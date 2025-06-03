//
//  RewardsStore.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI
import Foundation
import CloudKit

@MainActor
class RewardsStore: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    
    @Published var rewards: [Reward] = Reward.catalog
    @Published var collectedRewards: [CollectedReward] = [] // CloudKit CollectedReward records
    
    var currentKidID: CKRecord.ID?
    
    var coins: Int {
        CoinManager.shared.kidCoins
    }
    
    @Published private(set) var headerState: HeaderType = .normal {
        didSet {
            // Criar timer pra voltar pro normal
        }
    }
    
    init() {
        self.rewards = Reward.catalog
        
        // Carrega dados do UserManager
        loadFromUserManager()
    }
    
    func setHeaderNormal() {
        self.headerState = .normal
    }
    
    func setHeaderMessage(_ message: String, color: Color = .message) {
        
        self.headerState = .withMessage(message, color)
        
    }
    
    func collectReward(reward: Reward) throws {
        try buyReward(reward)
    }
    
    func loadFromUserManager() {
        let userManager = UserManager.shared
        
        if let kidID = userManager.currentKidID {
            print("RewardsStore: Carregando kid do UserManager - ID: \(kidID.recordName)")
            self.currentKidID = kidID
            
            // Configura o CoinManager
            CoinManager.shared.setCurrentKid(kidID)
            
            // Carrega apenas as recompensas
            if userManager.isChild {
                loadSharedCollectedRewards()
            } else {
                loadCollectedRewards()
            }
        } else if let rootRecordID = CloudService.shared.getRootRecordID() {
            print("RewardsStore: Carregando kid do rootRecordID")
            self.currentKidID = rootRecordID
            
            // Configura o CoinManager
            CoinManager.shared.setCurrentKid(rootRecordID)
            
            loadSharedCollectedRewards()
        } else {
            print("RewardsStore: Nenhum kid encontrado")
        }
    }
}


// MARK: - Kid Management
extension RewardsStore {
    
    func setCurrentKid(_ kidID: CKRecord.ID) {
        self.currentKidID = kidID
        loadKidData()
    }
    
    func loadFromRootRecord() {
        guard let rootRecordID = CloudService.shared.getRootRecordID() else {
            handleError("No shared kid found")
            return
        }
        
        self.currentKidID = rootRecordID
        loadSharedKidData()
    }
    
    func loadKidData() {
            guard let kidID = currentKidID else {
                print("RewardsStore: loadKidData - Nenhum kidID definido")
                return
            }
            
            print("RewardsStore: Carregando dados do kid: \(kidID.recordName)")
            isLoading = true
            
            // Atualiza o CoinManager com o kid atual
            CoinManager.shared.setCurrentKid(kidID)
            
            // Carrega apenas as recompensas coletadas
            loadCollectedRewards()
        }
    
    private func loadSharedKidData() {
        guard let kidID = currentKidID else {
            print("RewardsStore: loadSharedKidData - Nenhum kidID definido")
            return
        }
        
        print("RewardsStore: Carregando dados compartilhados do kid: \(kidID.recordName)")
        isLoading = true
        
        // Atualiza o CoinManager
        CoinManager.shared.setCurrentKid(kidID)
        
        // Carrega apenas as recompensas
        loadSharedCollectedRewards()
    }
}


// MARK: - Rewards Management
extension RewardsStore {
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
}

extension RewardsStore {
    
    func buyReward(_ reward: Reward) throws {
        guard let kidID = currentKidID else {
            handleError("No kid selected")
            return
        }
        
        // Check if kid has enough coins
        guard CoinManager.shared.canAfford(cost: reward.cost) else {
            handleError("Insufficient coins to buy \(reward.name)")
            throw RewardsStoreError.notEnoughCoins
        }
        
        isLoading = true
        
        Task {
            do {
                // 1. Primeiro remove as moedas
                try await CoinManager.shared.removeCoins(reward.cost, reason: "Compra: \(reward.name)")
                
                // 2. Adiciona a recompensa aos pendingRewards do Kid
                try await addRewardToPending(rewardID: reward.id, kidID: kidID)
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.setHeaderMessage("✅ \(reward.name) comprado!", color: .green)
                }
                
            } catch {
                // Se falhar, devolve as moedas
                try? await CoinManager.shared.addCoins(reward.cost, reason: "Estorno: \(reward.name)")
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.handleError("Failed to purchase reward: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func addRewardToPending(rewardID: Int, kidID: CKRecord.ID) async throws {
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
        let isChildUser = UserManager.shared.isChild
        let database = (isSharedZone || isChildUser) ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        // Busca o registro do Kid
        let record = try await database.record(for: kidID)
        
        // Adiciona o rewardID ao array de pendingRewards com timestamp
        var pendingRewards = record["pendingRewards"] as? [Int] ?? []
        var pendingDates = record["pendingRewardDates"] as? [Date] ?? []
        
        pendingRewards.append(rewardID)
        pendingDates.append(Date())
        
        record["pendingRewards"] = pendingRewards
        record["pendingRewardDates"] = pendingDates
        
        // Salva o registro atualizado
        _ = try await database.save(record)
    }
}


// MARK: - CollectedReward Management
extension RewardsStore {
    
    func deleteCollectedReward(_ collectedReward: CollectedReward) {
        isLoading = true
        
        guard let rewardID = collectedReward.id else {
            isLoading = false
            handleError("Invalid reward ID")
            return
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let database = UserManager.shared.isChild ? container.sharedCloudDatabase : container.privateCloudDatabase
        
        Task {
            do {
                // Deleta o registro
                let deletedID = try await database.deleteRecord(withID: rewardID)
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    // Remove from local list
                    self?.collectedRewards.removeAll { $0.id == deletedID }
                }
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
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
        
        let isSharedUser = UserManager.shared.isChild
        
        if isSharedUser {
            CloudService.shared.fetchSharedCollectedRewards(forKid: kidID.recordName) { [weak self] result in
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
        } else {
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
}

// MARK: - Father Operations
extension RewardsStore {
    
    func markRewardAsDelivered(_ collectedReward: CollectedReward) {
        isLoading = true
        
        guard let rewardID = collectedReward.id else {
            isLoading = false
            handleError("Invalid reward ID")
            return
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let database = UserManager.shared.isChild ? container.sharedCloudDatabase : container.privateCloudDatabase
        
        Task {
            do {
                // Busca o registro mais recente antes de atualizar
                let record = try await database.record(for: rewardID)
                
                // Atualiza o campo
                record["isDelivered"] = true
                
                // Salva o registro atualizado
                let savedRecord = try await database.save(record)
                
                if let updatedReward = CollectedReward(record: savedRecord) {
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                        // Update local list
                        if let index = self?.collectedRewards.firstIndex(where: { $0.id == collectedReward.id }) {
                            self?.collectedRewards[index] = updatedReward
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                        self?.handleError("Failed to update reward status")
                    }
                }
                
            } catch let error as CKError {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    if error.code == .serverRecordChanged {
                        self?.handleError("Reward was modified by another device. Please refresh and try again.")
                    } else {
                        self?.handleError("Failed to mark as delivered: \(error.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
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

// MARK: - Debug
extension RewardsStore {
    var debugDescription: String {
        """
        RewardsStore Debug:
        - Current Kid ID: \(currentKidID?.recordName ?? "None")
        - Coins: \(coins)
        - Collected Rewards: \(collectedRewards.count)
        - Is Loading: \(isLoading)
        """
    }
    
    enum HeaderType {
        case normal
        case withMessage(String, Color)
        
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
    case noKidSelected
}
