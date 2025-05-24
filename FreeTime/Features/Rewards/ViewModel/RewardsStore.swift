//
//  RewardsStore.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI
import Foundation
import CloudKit

class RewardsStore: ObservableObject {
    @Published var rewards: [Reward]
    @Published var coins: Int = 0
    @Published var cloudCollectedRewards: [CollectedReward] = [] // CloudKit records
    @Published var isLoading = false
    private var currentKidID: CKRecord.ID?
    
    init() {
        self.rewards = RewardsStore.getRewards()
    }
    
    static func getRewards() -> [Reward] {
        return Reward.catalog
    }
}

// MARK: - Hybrid CloudKit Operations (Local + Cloud Sync)
extension RewardsStore {
    
    func loadDataForKid(_ kidID: CKRecord.ID, completion: @escaping (Result<Void, CloudError>) -> Void) {
        self.currentKidID = kidID
        isLoading = true
        
        // Load Kid data (coins + legacy collectedRewards)
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            switch result {
            case .success(let kid):
                // Load cloud-based CollectedRewards separately
                self?.loadCloudCollectedRewards(kidID) { cloudResult in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        // Update local state with Kid data
                        self?.coins = kid.coins
                        self?.collectedRewards = kid.collectedRewards
                        
                        completion(.success(()))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func loadCloudCollectedRewards(_ kidID: CKRecord.ID, completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidName = kidID.recordName as String? else {
            completion(.failure(.recordNotFound))
            return
        }
        
        CloudService.shared.fetchAllCollectedRewards(forKid: kidName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cloudRewards):
                    self?.cloudCollectedRewards = cloudRewards
                    completion(.success(()))
                case .failure(let error):
                    print("Warning: Could not load cloud collected rewards: \(error)")
                    completion(.success(())) // Continue without cloud rewards
                }
            }
        }
    }
    
    // MARK: - Hybrid Coin Operations (Local update + Cloud sync)
    
    /// Add coins locally and sync to CloudKit
    func addCoins(_ amount: Int, completion: @escaping (Result<Void, CloudError>) -> Void) {
        // 1. Update locally immediately
        coins += amount
        
        // 2. Sync to CloudKit
        syncCoinsToCloudKit(completion: completion)
    }
    
    /// Remove coins locally and sync to CloudKit
    func removeCoins(_ amount: Int, completion: @escaping (Result<Void, CloudError>) -> Void) {
        // 1. Update locally immediately
        coins = max(0, coins - amount)
        
        // 2. Sync to CloudKit
        syncCoinsToCloudKit(completion: completion)
    }
    
    // MARK: - Hybrid Reward Operations
    
    /// Collect reward with immediate local update + cloud persistence
    func collectReward(reward: Reward, completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        // Check if we have enough coins
        guard coins >= reward.cost else {
            completion(.failure(.notEnoughCoins))
            return
        }
        
        // 1. Update local coins immediately
        coins -= reward.cost
        
        // 2. Create and save CloudKit CollectedReward
        var cloudReward = CollectedReward(kidID: kidID.recordName, rewardID: reward.id, dateCollected: Date(), isDelivered: false)
        cloudReward.kidReference = CKRecord.Reference(recordID: kidID, action: .deleteSelf)
        
        CloudService.shared.saveCollectedReward(cloudReward) { [weak self] cloudResult in
            DispatchQueue.main.async {
                switch cloudResult {
                case .success(let savedCloudReward):
                    // Add to cloud rewards list
                    self?.cloudCollectedRewards.append(savedCloudReward)
                    
                    // Also add to legacy format for backward compatibility
                    if let reward = savedCloudReward.reward {
                        let legacyReward = CollectedReward(reward: reward, date: savedCloudReward.dateCollected)
                        self?.collectedRewards.append(legacyReward)
                    }
                    
                    // 3. Sync coins to CloudKit
                    self?.syncCoinsToCloudKit { syncResult in
                        DispatchQueue.main.async {
                            switch syncResult {
                            case .success:
                                print("✅ Reward collected and synced successfully")
                                completion(.success(()))
                            case .failure(let error):
                                print("⚠️ Reward saved but coin sync failed: \(error)")
                                completion(.success(())) // Don't revert, just notify
                            }
                        }
                    }
                case .failure(let error):
                    // Revert local coin change if cloud save failed
                    self?.coins += reward.cost
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Remove collected reward locally and sync to CloudKit
    func removeCollectedReward(by id: UUID, completion: @escaping (Result<Void, CloudError>) -> Void) {
        // 1. Update locally immediately
        collectedRewards.removeAll { $0.id == id }
        
        // 2. Sync to CloudKit
        syncCollectedRewardsToCloudKit(completion: completion)
    }
    
    func removeCollectedReward(by rewardID: Int, completion: @escaping (Result<Void, CloudError>) -> Void) {
        // 1. Update locally immediately
        collectedRewards.removeAll { $0.reward.id == rewardID }
        
        // 2. Sync to CloudKit
        syncCollectedRewardsToCloudKit(completion: completion)
    }
    
    // MARK: - Father Operations (Cloud Rewards Management)
    
    /// Mark cloud reward as delivered (for fathers)
    func markRewardAsDelivered(_ cloudReward: CollectedReward, completion: @escaping (Result<Void, CloudError>) -> Void) {
        var updatedReward = cloudReward
        updatedReward.isDelivered = true
        
        CloudService.shared.updateCollectedReward(updatedReward, isShared: false) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedReward):
                    // Update local cloud rewards list
                    if let index = self?.cloudCollectedRewards.firstIndex(where: { $0.id == cloudReward.id }) {
                        self?.cloudCollectedRewards[index] = savedReward
                    }
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Get pending (undelivered) rewards for father's view
    func getPendingRewards() -> [CollectedReward] {
        return cloudCollectedRewards.filter { !$0.isDelivered }
    }
    
    /// Get delivered rewards
    func getDeliveredRewards() -> [CollectedReward] {
        return cloudCollectedRewards.filter { $0.isDelivered }
    }
    
    // MARK: - CloudKit Sync Methods (Internal)
    
    private func syncCoinsToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var kid):
                let currentKidCoins = kid.coins
                let targetCoins = self.coins
                
                if targetCoins > currentKidCoins {
                    kid.addCoins(targetCoins - currentKidCoins)
                } else if targetCoins < currentKidCoins {
                    kid.removeCoins(currentKidCoins - targetCoins)
                }
                
                guard let recordToSave = kid.record else {
                    DispatchQueue.main.async {
                        completion(.failure(.recordNotFound))
                    }
                    return
                }
                
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let privateDB = container.privateCloudDatabase
                
                Task {
                    do {
                        let savedRecord = try await privateDB.save(recordToSave)
                        
                        if let updatedKid = Kid(record: savedRecord) {
                            DispatchQueue.main.async {
                                self.coins = updatedKid.coins
                                completion(.success(()))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(.recordNotFound))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(.couldNotSaveRecord))
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func syncCollectedRewardsToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var kid):
                kid.collectedRewards = self.collectedRewards
                
                guard let recordToSave = kid.record else {
                    DispatchQueue.main.async {
                        completion(.failure(.recordNotFound))
                    }
                    return
                }
                
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let privateDB = container.privateCloudDatabase
                
                Task {
                    do {
                        let savedRecord = try await privateDB.save(recordToSave)
                        
                        if let updatedKid = Kid(record: savedRecord) {
                            DispatchQueue.main.async {
                                self.collectedRewards = updatedKid.collectedRewards
                                completion(.success(()))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(.recordNotFound))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(.couldNotSaveRecord))
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
}
