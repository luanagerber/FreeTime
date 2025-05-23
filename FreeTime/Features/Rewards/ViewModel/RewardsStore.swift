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
    @Published var collectedRewards: [CollectedReward] = []
    @Published var isLoading = false
    
    private var currentKidID: CKRecord.ID?
    
    @Published var kid: Kid
    
    init() {
        self.rewards = RewardsStore.getRewards()
        kid = Kid.sample
    }
    
    // MARK: - Local Operations (UI Updates)
    
    func collectReward(reward: Reward) throws {
        guard coins >= reward.cost else {
            throw RewardsStoreError.notEnoughCoins
        }
        
        let collectedReward = CollectedReward(reward: reward, date: Date())
        collectedRewards.append(collectedReward)
        coins -= reward.cost
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
    }
    
    func removeCoins(_ amount: Int) {
        coins = max(0, coins - amount)
    }
    
    func removeCollectedReward(by id: UUID) {
        collectedRewards.removeAll { $0.id == id }
    }
    
    func removeCollectedReward(by rewardID: Int) {
        collectedRewards.removeAll { $0.reward.id == rewardID }
    }
    
    static func getRewards() -> [Reward] {
        return Reward.catalog
    }
}

// MARK: - CloudKit Operations
extension RewardsStore {
    
    func loadDataForKid(_ kidID: CKRecord.ID, completion: @escaping (Result<Void, CloudError>) -> Void) {
        self.currentKidID = kidID
        isLoading = true
        
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let kid):
                    self?.coins = kid.coins
                    self?.collectedRewards = kid.collectedRewards
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func syncCoinsToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        // Fetch current kid, update coins, save back
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var kid):
                // Calculate the difference and update using the methods
                let currentKidCoins = kid.coins
                let targetCoins = self.coins
                
                if targetCoins > currentKidCoins {
                    kid.addCoins(targetCoins - currentKidCoins)
                } else if targetCoins < currentKidCoins {
                    kid.removeCoins(currentKidCoins - targetCoins)
                }
                
                // IMPORTANT: Preserve the associatedRecord for proper CloudKit updates
                guard let recordToSave = kid.record else {
                    DispatchQueue.main.async {
                        completion(.failure(.recordNotFound))
                    }
                    return
                }
                
                // Use CloudKit directly to ensure the update happens
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let privateDB = container.privateCloudDatabase
                
                Task {
                    do {
                        let savedRecord = try await privateDB.save(recordToSave)
                        
                        // Create updated kid from saved record
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
    
    func syncCollectedRewardsToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        // Fetch current kid, update collected rewards, save back
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var kid):
                // Update collected rewards (this can be assigned directly)
                kid.collectedRewards = self.collectedRewards
                
                // IMPORTANT: Preserve the associatedRecord for proper CloudKit updates
                guard let recordToSave = kid.record else {
                    DispatchQueue.main.async {
                        completion(.failure(.recordNotFound))
                    }
                    return
                }
                
                // Use CloudKit directly to ensure the update happens
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let privateDB = container.privateCloudDatabase
                
                Task {
                    do {
                        let savedRecord = try await privateDB.save(recordToSave)
                        
                        // Create updated kid from saved record
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
    
    func syncAllToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        // Fetch current kid, update both coins and collected rewards, save back
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var kid):
                // Update coins using the proper methods
                let currentKidCoins = kid.coins
                let targetCoins = self.coins
                
                if targetCoins > currentKidCoins {
                    kid.addCoins(targetCoins - currentKidCoins)
                } else if targetCoins < currentKidCoins {
                    kid.removeCoins(currentKidCoins - targetCoins)
                }
                
                // Update collected rewards (this can be assigned directly)
                kid.collectedRewards = self.collectedRewards
                
                // IMPORTANT: Preserve the associatedRecord for proper CloudKit updates
                guard let recordToSave = kid.record else {
                    DispatchQueue.main.async {
                        completion(.failure(.recordNotFound))
                    }
                    return
                }
                
                // Use CloudKit directly to ensure the update happens
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let privateDB = container.privateCloudDatabase
                
                Task {
                    do {
                        let savedRecord = try await privateDB.save(recordToSave)
                        
                        // Create updated kid from saved record
                        if let updatedKid = Kid(record: savedRecord) {
                            DispatchQueue.main.async {
                                self.coins = updatedKid.coins
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
    
    // MARK: - Convenience Functions (Local + Sync)
    
    func collectRewardAndSync(reward: Reward, completion: @escaping (Result<Void, CloudError>) -> Void) {
        do {
            try collectReward(reward: reward)
            // Sync both coins and collected rewards since both changed
            syncAllToCloudKit(completion: completion)
        } catch {
            completion(.failure(.notEnoughCoins))
        }
    }
    
    func addCoinsAndSync(_ amount: Int, completion: @escaping (Result<Void, CloudError>) -> Void) {
        addCoins(amount)
        syncCoinsToCloudKit(completion: completion)
    }
    
    func removeCoinsAndSync(_ amount: Int, completion: @escaping (Result<Void, CloudError>) -> Void) {
        removeCoins(amount)
        syncCoinsToCloudKit(completion: completion)
    }
    
    func removeCollectedRewardAndSync(by id: UUID, completion: @escaping (Result<Void, CloudError>) -> Void) {
        removeCollectedReward(by: id)
        syncCollectedRewardsToCloudKit(completion: completion)
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
}
