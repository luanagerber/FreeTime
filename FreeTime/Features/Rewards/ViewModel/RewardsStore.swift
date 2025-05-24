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
    @Published var rewards: [Reward] = Reward.catalog
    @Published var coins: Int = 0
    @Published var collectedRewards: [CollectedReward] = [] // CloudKit CollectedReward records
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    
    var currentKidID: CKRecord.ID?
    
    init() {
        self.rewards = Reward.catalog
        
        // Carrega automaticamente o kid compartilhado se existir
        if let rootRecordID = CloudService.shared.getRootRecordID() {
            self.currentKidID = rootRecordID
            loadSharedKidData()
        }
    }
}

// MARK: - Kid Management
extension RewardsStore {
    
    func setCurrentKid(_ kidID: CKRecord.ID) {
        self.currentKidID = kidID
        loadKidData()
    }
    
    func loadKidData() {
        guard let kidID = currentKidID else { return }
        
        isLoading = true
        
        // Tenta primeiro no banco privado (para kids próprios)
        CloudService.shared.fetchPrivateKid(withRecordID: kidID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let kid):
                    self?.coins = kid.coins
                    self?.loadCollectedRewards()
                case .failure:
                    // Se falhar no privado, tenta no compartilhado
                    CloudService.shared.fetchKid(withRecordID: kidID) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let kid):
                                self?.coins = kid.coins
                            case .failure(let error):
                                self?.handleError("Failed to load kid data: \(error.localizedDescription)")
                            }
                            self?.loadCollectedRewards()
                        }
                    }
                }
            }
        }
    }
    
    ////??? Luana
    func loadFromRootRecord() {
        guard let rootRecordID = CloudService.shared.getRootRecordID() else {
            handleError("No shared kid found")
            return
        }
        
        self.currentKidID = rootRecordID
        loadSharedKidData()
    }
    
    private func loadSharedCollectedRewards() {
        guard let kidID = currentKidID else {
            isLoading = false
            return
        }
        
        CloudService.shared.fetchSharedCollectedRewards(forKid: kidID.recordName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let rewards):
                    self?.collectedRewards = rewards
                case .failure(let error):
                    self?.handleError("Failed to load shared rewards: \(error.localizedDescription)")
                    self?.collectedRewards = []
                }
            }
        }
    }
    
    private func loadSharedKidData() {
        guard let kidID = currentKidID else { return }
        
        isLoading = true
        
        // Busca kid compartilhado
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let kid):
                    self?.coins = kid.coins
                    self?.loadSharedCollectedRewards()
                case .failure(let error):
                    self?.handleError("Failed to load shared kid: \(error.localizedDescription)")
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func loadCollectedRewards() {
        guard let kidID = currentKidID else {
            isLoading = false
            return
        }
        
        CloudService.shared.fetchAllCollectedRewards(forKid: kidID.recordName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let rewards):
                    self?.collectedRewards = rewards
                case .failure(let error):
                    self?.handleError("Failed to load collected rewards: \(error.localizedDescription)")
                    self?.collectedRewards = []
                }
            }
        }
    }
}

// MARK: - Coin Operations
extension RewardsStore {
    
    func addCoins(_ amount: Int) {
        guard currentKidID != nil else {
            handleError("No kid selected")
            return
        }
        
        // Update locally immediately
        coins += amount
        
        // Sync to CloudKit
        syncCoinsToCloudKit { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break // Success
                case .failure(let error):
                    self?.handleError("Failed to sync coins: \(error.localizedDescription)")
                    // Revert local change
                    self?.coins -= amount
                }
            }
        }
    }
    
    func removeCoins(_ amount: Int) {
        guard currentKidID != nil else {
            handleError("No kid selected")
            return
        }
        
        let oldCoins = coins
        // Update locally immediately
        coins = max(0, coins - amount)
        
        // Sync to CloudKit
        syncCoinsToCloudKit { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break // Success
                case .failure(let error):
                    self?.handleError("Failed to sync coins: \(error.localizedDescription)")
                    // Revert local change
                    self?.coins = oldCoins
                }
            }
        }
    }
    
    // MARK: - Private CloudKit Helper
    private func syncCoinsToCloudKit(completion: @escaping (Result<Void, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            completion(.failure(.recordNotFound))
            return
        }
        
        CloudService.shared.fetchKid(withRecordID: kidID) { [weak self] result in
            switch result {
            case .success(var kid):
                let currentKidCoins = kid.coins
                let targetCoins = self?.coins ?? 0
                
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
                                self?.coins = updatedKid.coins
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

// MARK: - Reward Purchase (Kid Operations)
extension RewardsStore {
    
    func buyReward(_ reward: Reward) {
        guard let kidID = currentKidID else {
            handleError("No kid selected")
            return
        }
        
        // Check if kid has enough coins
        guard coins >= reward.cost else {
            handleError("Insufficient coins to buy \(reward.name)")
            return
        }
        
        isLoading = true
        
        // Decrease coins locally immediately
        let oldCoins = coins
        coins -= reward.cost
        
        // Create CollectedReward record
        var collectedReward = CollectedReward(
            kidID: kidID.recordName,
            rewardID: reward.id,
            dateCollected: Date(),
            isDelivered: false
        )
        collectedReward.kidReference = CKRecord.Reference(recordID: kidID, action: .deleteSelf)
        
        // Save to CloudKit
        CloudService.shared.saveCollectedReward(collectedReward) { [weak self] rewardResult in
            DispatchQueue.main.async {
                switch rewardResult {
                case .success(let savedReward):
                    // Add to local list
                    self?.collectedRewards.append(savedReward)
                    
                    // Update coins in CloudKit
                    self?.syncCoinsToCloudKit { coinResult in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            switch coinResult {
                            case .success:
                                break // Success
                            case .failure(let error):
                                // Revert local changes if coin sync failed
                                self?.coins = oldCoins
                                self?.collectedRewards.removeAll { $0.id == savedReward.id }
                                self?.handleError("Failed to sync purchase: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                case .failure(let error):
                    self?.isLoading = false
                    // Revert coin change if reward save failed
                    self?.coins = oldCoins
                    self?.handleError("Failed to purchase reward: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func canAfford(_ reward: Reward) -> Bool {
        return coins >= reward.cost
    }
}

// MARK: - CollectedReward Management
extension RewardsStore {
    
    func deleteCollectedReward(_ collectedReward: CollectedReward) {
        isLoading = true
        
        CloudService.shared.deleteCollectedReward(collectedReward, isShared: false) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    // Remove from local list
                    self?.collectedRewards.removeAll { $0.id == collectedReward.id }
                case .failure(let error):
                    self?.handleError("Failed to delete reward: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func refreshCollectedRewards() {
        guard let kidID = currentKidID else {
            handleError("No kid selected")
            return
        }
        
        isLoading = true
        
        CloudService.shared.fetchAllCollectedRewards(forKid: kidID.recordName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let rewards):
                    self?.collectedRewards = rewards
                case .failure(let error):
                    self?.handleError("Failed to refresh rewards: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Father Operations
extension RewardsStore {
    
    func markRewardAsDelivered(_ collectedReward: CollectedReward) {
        isLoading = true
        
        var updatedReward = collectedReward
        updatedReward.isDelivered = true
        
        CloudService.shared.updateCollectedReward(updatedReward, isShared: false) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let savedReward):
                    // Update local list
                    if let index = self?.collectedRewards.firstIndex(where: { $0.id == collectedReward.id }) {
                        self?.collectedRewards[index] = savedReward
                    }
                case .failure(let error):
                    self?.handleError("Failed to mark as delivered: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getPendingRewards() -> [CollectedReward] {
        return collectedRewards.filter { !$0.isDelivered }
    }
    
    func getDeliveredRewards() -> [CollectedReward] {
        return collectedRewards.filter { $0.isDelivered }
    }
}

// MARK: - Test/Debug Operations
extension RewardsStore {
    
    func createTestKid(name: String = "Test Kid") {
        isLoading = true
        
        let kid = Kid(name: name, coins: 100) // Start with 100 coins for testing
        
        CloudService.shared.saveKid(kid) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let savedKid):
                    self?.currentKidID = savedKid.id
                    self?.loadKidData()
                case .failure(let error):
                    self?.handleError("Failed to create test kid: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Error Handling
extension RewardsStore {
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("RewardsStore Error: \(message)")
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
}
