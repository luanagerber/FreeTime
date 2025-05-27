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
    
    // NOVA PROPRIEDADE: Referência ao UserManager
    private let userManager = UserManager.shared
    
    init() {
        self.rewards = Reward.catalog
        
        // Carrega dados do UserManager
        loadFromUserManager()
    }
    
    private func loadFromUserManager() {
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        print("RewardsStore: Is child: \(userManager.isChild)")
        print("RewardsStore: Is parent: \(userManager.isParent)")
        
        // Se o UserManager tem um kid válido, use-o
        if let kidID = userManager.currentKidID {
            print("RewardsStore: Carregando kid do UserManager - ID: \(kidID.recordName), Nome: \(userManager.currentKidName)")
            self.currentKidID = kidID
            
            // Carrega dados baseado no tipo de usuário
            if userManager.isChild {
                loadSharedKidData()
            } else {
                loadKidData()
            }
        } else if let rootRecordID = CloudService.shared.getRootRecordID() {
            // Fallback para o método antigo se necessário
            print("RewardsStore: Carregando kid do rootRecordID")
            self.currentKidID = rootRecordID
            loadSharedKidData()
        } else {
            print("RewardsStore: Nenhum kid encontrado no UserManager ou rootRecordID")
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
        guard let kidID = currentKidID else {
            print("RewardsStore: loadKidData - Nenhum kidID definido")
            return
        }
        
        print("RewardsStore: Carregando dados do kid: \(kidID.recordName)")
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        isLoading = true
        
        // NOVA LÓGICA: Baseada no userRole
        if userManager.isChild {
            // Para crianças: sempre usar banco compartilhado
            loadSharedKidData()
        } else {
            // Para pais: usar banco privado primeiro, fallback para compartilhado
            CloudService.shared.fetchPrivateKid(withRecordID: kidID) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let kid):
                        print("RewardsStore: Kid encontrado no banco privado - Moedas: \(kid.coins)")
                        self?.coins = kid.coins
                        self?.loadCollectedRewards()
                    case .failure(let error):
                        print("RewardsStore: Falha no banco privado: \(error), tentando banco compartilhado...")
                        
                        // Se falhar no privado, tenta no compartilhado
                        CloudService.shared.fetchKid(withRecordID: kidID) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let kid):
                                    print("RewardsStore: Kid encontrado no banco compartilhado - Moedas: \(kid.coins)")
                                    self?.coins = kid.coins
                                case .failure(let error):
                                    print("RewardsStore: Falha ao carregar kid: \(error)")
                                    self?.handleError("Failed to load kid data: \(error.localizedDescription)")
                                }
                                self?.loadCollectedRewards()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadFromRootRecord() {
        guard let rootRecordID = CloudService.shared.getRootRecordID() else {
            handleError("No shared kid found")
            return
        }
        
        self.currentKidID = rootRecordID
        loadSharedKidData()
    }
    
    private func loadSharedKidData() {
        guard let kidID = currentKidID else {
            print("RewardsStore: loadSharedKidData - Nenhum kidID definido")
            return
        }
        
        print("RewardsStore: Carregando dados compartilhados do kid: \(kidID.recordName)")
        print("RewardsStore: Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        isLoading = true
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        // CORREÇÃO: Determinar qual banco usar baseado no owner da zona
        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
        let database = isSharedZone ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        print("RewardsStore: Usando \(isSharedZone ? "banco compartilhado" : "banco privado")")
        
        Task {
            do {
                let record = try await database.record(for: kidID)
                print("✅ RewardsStore: Kid encontrado - Moedas: \(record["coins"] ?? 0)")
                
                DispatchQueue.main.async { [weak self] in
                    if let kid = Kid(record: record) {
                        self?.coins = kid.coins
                        self?.loadSharedCollectedRewards()
                    } else {
                        self?.handleError("Failed to convert record to Kid")
                        self?.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("❌ RewardsStore: Erro ao carregar kid: \(error)")
                    self?.handleError("Failed to load kid: \(error.localizedDescription)")
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
        
        // NOVA LÓGICA: Baseada no userRole
        if userManager.isChild {
            loadSharedCollectedRewards()
        } else {
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

// MARK: - Coin Operations
extension RewardsStore {
    
    func addCoins(_ amount: Int) {
        guard let kidID = currentKidID else {
            print("RewardsStore: addCoins - Nenhum kid selecionado")
            handleError("No kid selected")
            return
        }
        
        print("RewardsStore: Adicionando \(amount) moedas. Total atual: \(coins)")
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        
        // Update locally immediately
        coins += amount
        
        // Sync to CloudKit
        syncCoinsToCloudKit { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("RewardsStore: Moedas sincronizadas com sucesso")
                case .failure(let error):
                    print("RewardsStore: Erro ao sincronizar moedas: \(error)")
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
            print("RewardsStore: syncCoinsToCloudKit - Nenhum kidID")
            completion(.failure(.recordNotFound))
            return
        }
        
        let targetCoins = self.coins
        print("RewardsStore: syncCoinsToCloudKit - Objetivo: atualizar para \(targetCoins) moedas")
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        
        // Busca diretamente o registro mais recente do CloudKit
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        // NOVA LÓGICA: Determinar banco baseado no userRole
        let database: CKDatabase
        if userManager.isChild {
            // Para crianças: sempre usar banco compartilhado
            database = container.sharedCloudDatabase
            print("RewardsStore: Usando banco compartilhado para sincronizar moedas")
        } else {
            // Para pais: usar banco privado
            database = container.privateCloudDatabase
            print("RewardsStore: Usando banco privado para sincronizar moedas")
        }
        
        Task {
            do {
                // Busca o registro mais recente
                let record = try await database.record(for: kidID)
                print("RewardsStore: Registro encontrado, moedas atuais no CloudKit: \(record["coins"] ?? "nil")")
                
                // Atualiza o valor das moedas
                record["coins"] = targetCoins
                
                // Salva o registro atualizado
                let savedRecord = try await database.save(record)
                print("RewardsStore: Registro salvo, moedas no CloudKit agora: \(savedRecord["coins"] ?? "nil")")
                
                DispatchQueue.main.async {
                    // Confirma que as moedas locais estão corretas
                    self.coins = targetCoins
                    completion(.success(()))
                }
                
            } catch let error as CKError {
                print("RewardsStore: Erro CKError ao sincronizar: \(error.localizedDescription)")
                if error.code == .serverRecordChanged {
                    // Em caso de conflito, tenta novamente
                    print("RewardsStore: Conflito de versão detectado, tentando novamente...")
                    DispatchQueue.main.async {
                        self.syncCoinsToCloudKit(completion: completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.couldNotSaveRecord))
                    }
                }
            } catch {
                print("RewardsStore: Erro geral ao sincronizar: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.couldNotSaveRecord))
                }
            }
        }
    }
}

// MARK: - Reward Purchase (Kid Operations)
extension RewardsStore {
    
    func buyReward(_ reward: Reward) {
        guard let kidID = currentKidID else {
            print("RewardsStore: buyReward - Nenhum kid selecionado")
            handleError("No kid selected")
            return
        }
        
        // Check if kid has enough coins
        guard coins >= reward.cost else {
            handleError("Insufficient coins to buy \(reward.name)")
            return
        }
        
        print("RewardsStore: Comprando recompensa: \(reward.name)")
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        
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
        
        // NOVA LÓGICA: Salvar baseado no userRole
        if userManager.isChild {
            // Para crianças: salvar no banco compartilhado
            saveCollectedRewardShared(collectedReward) { [weak self] rewardResult in
                self?.handleRewardPurchaseResult(rewardResult, oldCoins: oldCoins, savedReward: nil)
            }
        } else {
            // Para pais: salvar no banco privado (método original)
            CloudService.shared.saveCollectedReward(collectedReward) { [weak self] rewardResult in
                switch rewardResult {
                case .success(let savedReward):
                    self?.handleRewardPurchaseResult(.success(savedReward), oldCoins: oldCoins, savedReward: savedReward)
                case .failure(let error):
                    self?.handleRewardPurchaseResult(.failure(error), oldCoins: oldCoins, savedReward: nil)
                }
            }
        }
    }
    
    private func saveCollectedRewardShared(_ collectedReward: CollectedReward, completion: @escaping (Result<CollectedReward, CloudError>) -> Void) {
        guard let kidID = currentKidID else {
            print("RewardsStore: saveCollectedRewardShared - Nenhum kidID")
            completion(.failure(.recordNotFound))
            return
        }
        
        print("RewardsStore: Salvando recompensa no banco compartilhado")
        print("RewardsStore: Kid Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        
        // CORREÇÃO: Criar o record na zona compartilhada correta
        let sharedRecord = CKRecord(
            recordType: RecordType.collectedReward.rawValue,
            zoneID: kidID.zoneID  // Usar a zona do kidID compartilhado
        )
        
        // Preencher os campos
        sharedRecord["kidID"] = collectedReward.kidID
        sharedRecord["rewardID"] = collectedReward.rewardID
        sharedRecord["dateCollected"] = collectedReward.dateCollected
        sharedRecord["isDelivered"] = collectedReward.isDelivered
        
        // Adicionar referência ao Kid se disponível
        if let kidRef = collectedReward.kidReference {
            sharedRecord["kidReference"] = kidRef
            print("RewardsStore: kidReference adicionada: \(kidRef.recordID.recordName)")
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let sharedDB = container.sharedCloudDatabase
        
        Task {
            do {
                // IMPORTANTE: Buscar o record do Kid primeiro para usar como parent
                print("RewardsStore: Buscando record do Kid para configurar hierarquia...")
                let kidRecord = try await sharedDB.record(for: kidID)
                print("RewardsStore: Kid record encontrado, configurando como parent...")
                
                // Configurar como filho do Kid para compartilhamento automático
                sharedRecord.setParent(kidRecord)
                print("RewardsStore: Parent configurado para compartilhamento automático")
                
                print("RewardsStore: Tentando salvar no banco compartilhado...")
                let savedRecord = try await sharedDB.save(sharedRecord)
                print("RewardsStore: ✅ Recompensa salva com sucesso: \(savedRecord.recordID.recordName)")
                
                if let savedReward = CollectedReward(record: savedRecord) {
                    DispatchQueue.main.async {
                        completion(.success(savedReward))
                    }
                } else {
                    print("RewardsStore: ❌ Erro na conversão do registro salvo")
                    DispatchQueue.main.async {
                        completion(.failure(.decodeError))
                    }
                }
            } catch {
                let errorDescription = error.localizedDescription
                print("RewardsStore: ❌ Erro ao salvar recompensa: \(errorDescription)")
                
                if let ckError = error as? CKError {
                    print("RewardsStore: CKError details: \(ckError.localizedDescription)")
                    print("RewardsStore: CKError code: \(ckError.code.rawValue)")
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.couldNotSave(error)))
                }
            }
        }
    }
    
    private func handleRewardPurchaseResult(_ rewardResult: Result<CollectedReward, CloudError>, oldCoins: Int, savedReward: CollectedReward?) {
        DispatchQueue.main.async { [weak self] in
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
                            print("RewardsStore: Compra realizada com sucesso!")
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
    
    func canAfford(_ reward: Reward) -> Bool {
        return coins >= reward.cost
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
        
        // NOVA LÓGICA: Determinar banco baseado no userRole
        let database: CKDatabase
        if userManager.isChild {
            database = container.sharedCloudDatabase
        } else {
            database = container.privateCloudDatabase
        }
        
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
        
        // NOVA LÓGICA: Baseada no userRole
        if userManager.isChild {
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
        
        // NOVA LÓGICA: Determinar banco baseado no userRole
        let database: CKDatabase
        if userManager.isChild {
            database = container.sharedCloudDatabase
        } else {
            database = container.privateCloudDatabase
        }
        
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
    
    // Método alternativo para adicionar moedas usando diretamente o Kid
    func addCoinsAlternative(_ amount: Int) {
        guard let kidID = currentKidID else {
            print("RewardsStore: addCoinsAlternative - Nenhum kid selecionado")
            handleError("No kid selected")
            return
        }
        
        print("RewardsStore: Usando método alternativo para adicionar \(amount) moedas")
        print("RewardsStore: User role: \(userManager.userRole.rawValue)")
        isLoading = true
        
        // Atualiza localmente primeiro
        let oldCoins = coins
        coins += amount
        
        // NOVA LÓGICA: Para crianças, usar syncCoinsToCloudKit ao invés de saveKid
        if userManager.isChild {
            syncCoinsToCloudKit { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success:
                        print("RewardsStore: Moedas atualizadas com sucesso via syncCoinsToCloudKit")
                    case .failure(let error):
                        print("RewardsStore: Erro ao atualizar moedas: \(error)")
                        self?.coins = oldCoins
                        self?.handleError("Failed to update coins: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Para pais: manter a lógica original
            var updatedKid = Kid(name: userManager.currentKidName, coins: coins)
            updatedKid.id = kidID
            
            CloudService.shared.saveKid(updatedKid) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let savedKid):
                        print("RewardsStore: Moedas atualizadas com sucesso para \(savedKid.coins)")
                        self?.coins = savedKid.coins
                    case .failure(let error):
                        print("RewardsStore: Erro ao atualizar moedas: \(error)")
                        self?.coins = oldCoins
                        self?.handleError("Failed to update coins: \(error.localizedDescription)")
                    }
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

// MARK: - Debug
extension RewardsStore {
    var debugDescription: String {
        """
        RewardsStore Debug:
        - Current Kid ID: \(currentKidID?.recordName ?? "None")
        - Coins: \(coins)
        - Collected Rewards: \(collectedRewards.count)
        - Is Loading: \(isLoading)
        - User Role: \(userManager.userRole.rawValue)
        - Is Child: \(userManager.isChild)
        - Is Parent: \(userManager.isParent)
        """
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
}
