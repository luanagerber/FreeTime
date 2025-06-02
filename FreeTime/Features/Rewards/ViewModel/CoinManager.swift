//
//  CoinManager.swift
//  FreeTime
//
//  Created by Luana Gerber on 29/05/25.
//

import SwiftUI
import CloudKit
import Combine

@MainActor
class CoinManager: ObservableObject {
    static let shared = CoinManager()
    
    @Published private(set) var kidCoins: Int = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage = ""
    
    private var currentKidID: CKRecord.ID?
    private let cloudService = CloudService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observa mudanças no UserManager
        NotificationCenter.default.publisher(for: .kidChanged)
            .sink { [weak self] _ in
                self?.reloadCoins()
            }
            .store(in: &cancellables)
    }
    
    func setCurrentKid(_ kidID: CKRecord.ID) {
        guard kidID != currentKidID else { return }
        currentKidID = kidID
        reloadCoins()
    }
    
    // MARK: - Coin Operations
    
    func reloadCoins() {
        guard let kidID = currentKidID ?? UserManager.shared.currentKidID else {
            print("CoinManager: Nenhum kid selecionado")
            kidCoins = 0
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let coins = try await fetchCoinsFromCloudKit(kidID: kidID)
                self.kidCoins = coins
                self.isLoading = false
                print("CoinManager: Moedas atualizadas: \(coins)")
            } catch {
                self.isLoading = false
                self.errorMessage = "Erro ao carregar moedas: \(error.localizedDescription)"
                print("CoinManager: Erro ao carregar moedas: \(error)")
            }
        }
    }
    
    func updateCoins(delta: Int, reason: String) async throws {
        guard let kidID = currentKidID ?? UserManager.shared.currentKidID else {
            throw CoinError.noKidSelected
        }
        
        let newValue = max(0, kidCoins + delta)
        print("CoinManager: Atualizando moedas - Delta: \(delta), Novo valor: \(newValue), Razão: \(reason)")
        
        // Atualiza localmente primeiro para feedback imediato
        let oldValue = kidCoins
        kidCoins = newValue
        
        do {
            try await saveCoinsToCloudKit(kidID: kidID, coins: newValue)
            print("CoinManager: ✅ Moedas sincronizadas com CloudKit")
            
            // Notifica outras partes do app
            NotificationCenter.default.post(
                name: .coinsUpdated,
                object: nil,
                userInfo: ["coins": newValue, "reason": reason]
            )
        } catch {
            // Reverte em caso de erro
            kidCoins = oldValue
            print("CoinManager: ❌ Erro ao sincronizar: \(error)")
            throw error
        }
    }
    
    func addCoins(_ amount: Int, reason: String) async throws {
        try await updateCoins(delta: amount, reason: reason)
    }
    
    func removeCoins(_ amount: Int, reason: String) async throws {
        try await updateCoins(delta: -amount, reason: reason)
    }
    
    // MARK: - Private CloudKit Methods
    
    private func fetchCoinsFromCloudKit(kidID: CKRecord.ID) async throws -> Int {
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
        let isChildUser = UserManager.shared.isChild
        let database = (isSharedZone || isChildUser) ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        let record = try await database.record(for: kidID)
        return record["coins"] as? Int ?? 0
    }
    
    private func saveCoinsToCloudKit(kidID: CKRecord.ID, coins: Int) async throws {
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
        let isChildUser = UserManager.shared.isChild
        let database = (isSharedZone || isChildUser) ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        // Busca o registro mais recente
        let record = try await database.record(for: kidID)
        record["coins"] = coins
        
        // Salva com retry em caso de conflito
        var retries = 3
        while retries > 0 {
            do {
                _ = try await database.save(record)
                return
            } catch let error as CKError where error.code == .serverRecordChanged {
                print("CoinManager: Conflito detectado, tentando novamente...")
                retries -= 1
                if retries > 0 {
                    // Recarrega o registro e tenta novamente
                    let freshRecord = try await database.record(for: kidID)
                    freshRecord["coins"] = coins
                    continue
                }
                throw error
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func canAfford(cost: Int) -> Bool {
        return kidCoins >= cost
    }
    
    var formattedCoins: String {
        return "\(kidCoins) 🪙"
    }
}

// MARK: - Error Types

enum CoinError: LocalizedError {
    case noKidSelected
    case insufficientCoins
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .noKidSelected:
            return "Nenhuma criança selecionada"
        case .insufficientCoins:
            return "Moedas insuficientes"
        case .syncFailed:
            return "Falha ao sincronizar moedas"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let coinsUpdated = Notification.Name("coinsUpdated")
    static let kidChanged = Notification.Name("kidChanged")
}


// Adicionar ao CoinManager para recuperação em caso de erro
extension CoinManager {
    func recoverFromError() {
        // Recarrega as moedas do CloudKit
        reloadCoins()
    }
    
    func forceSync() async {
        // Força uma sincronização com o CloudKit
        guard let kidID = currentKidID ?? UserManager.shared.currentKidID else { return }
        
        do {
            let cloudCoins = try await fetchCoinsFromCloudKit(kidID: kidID)
            if cloudCoins != kidCoins {
                print("CoinManager: Discrepância detectada. Local: \(kidCoins), Cloud: \(cloudCoins)")
                kidCoins = cloudCoins
            }
        } catch {
            print("CoinManager: Erro ao forçar sincronização: \(error)")
        }
    }
}
