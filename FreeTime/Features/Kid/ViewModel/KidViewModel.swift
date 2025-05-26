//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI
import CloudKit
import Combine

@MainActor
class KidViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var kid: Kid?
    @Published var activities: [ActivitiesRegister] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var feedbackMessage = ""
    @Published var hasAcceptedShareLink = false
    
    // MARK: - Private Properties
    private let cloudService = CloudService.shared
    private let invitationManager = InvitationStatusManager.shared
    var currentKidID: CKRecord.ID?
    
    // MARK: - Initialization
    init() {
        loadFromUserManager()
    }
    
    private func loadFromUserManager() {
        let userManager = UserManager.shared
        
        if let kidID = userManager.currentKidID {
            print("KidViewModel: Carregando kid do UserManager - ID: \(kidID.recordName), Nome: \(userManager.currentKidName)")
            self.currentKidID = kidID
            
            if userManager.isChild {
                loadSharedKidData()
            } else {
                loadKidData()
            }
        } else if let rootRecordID = cloudService.getRootRecordID() {
            print("KidViewModel: Carregando kid do rootRecordID")
            self.currentKidID = rootRecordID
            loadSharedKidData()
        } else {
            print("KidViewModel: Nenhum kid encontrado no UserManager ou rootRecordID")
        }
    }
}

// MARK: - Kid Management
extension KidViewModel {
    
    func setCurrentKid(_ kidID: CKRecord.ID) {
        self.currentKidID = kidID
        loadKidData()
    }
    
    func loadKidData() {
        guard let kidID = currentKidID else {
            print("KidViewModel: loadKidData - Nenhum kidID definido")
            return
        }
        
        print("KidViewModel: Carregando dados do kid: \(kidID.recordName)")
        isLoading = true
        
        // Tenta primeiro no banco privado (para kids próprios)
        cloudService.fetchPrivateKid(withRecordID: kidID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let kid):
                    print("KidViewModel: Kid encontrado no banco privado")
                    self?.kid = kid
                    self?.loadActivities()
                case .failure(let error):
                    print("KidViewModel: Falha no banco privado: \(error), tentando banco compartilhado...")
                    // Se falhar no privado, tenta no compartilhado
                    self?.cloudService.fetchKid(withRecordID: kidID) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let kid):
                                print("KidViewModel: Kid encontrado no banco compartilhado")
                                self?.kid = kid
                            case .failure(let error):
                                print("KidViewModel: Falha ao carregar kid: \(error)")
                                self?.handleError("Failed to load kid data: \(error.localizedDescription)")
                            }
                            self?.loadActivities()
                        }
                    }
                }
            }
        }
    }
    
    private func loadSharedKidData() {
        guard let kidID = currentKidID else {
            print("KidViewModel: loadSharedKidData - Nenhum kidID definido")
            return
        }
        
        print("KidViewModel: Carregando dados compartilhados do kid: \(kidID.recordName)")
        isLoading = true
        
        // Usa o mesmo método que funciona na KidReceiverView
        fetchKidInfo(rootRecordID: kidID)
    }
    
    func loadFromRootRecord() {
        guard let rootRecordID = cloudService.getRootRecordID() else {
            handleError("No shared kid found")
            return
        }
        
        self.currentKidID = rootRecordID
        loadSharedKidData()
    }
    
    private func fetchKidInfo(rootRecordID: CKRecord.ID) {
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let sharedDB = container.sharedCloudDatabase
        
        Task {
            do {
                let record = try await sharedDB.record(for: rootRecordID)
                print("✅ Registro compartilhado encontrado: \(record.recordID.recordName)")
                
                DispatchQueue.main.async { [weak self] in
                    if let fetchedKid = Kid(record: record) {
                        self?.kid = fetchedKid
                        self?.currentKidID = rootRecordID
                        self?.feedbackMessage = "✅ Conectado como \(fetchedKid.name)"
                        self?.loadActivities(for: fetchedKid, using: record.recordID.zoneID)
                    } else {
                        print("❌ Falha ao converter o registro para Kid")
                        self?.isLoading = false
                        self?.handleError("Failed to load kid information from shared record")
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("❌ Erro ao acessar registro compartilhado: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.handleError("Failed to load invitation: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Activities Management
extension KidViewModel {
    
    private func loadActivities() {
        guard let kid = kid else {
            isLoading = false
            return
        }
        
        guard let currentKidID = currentKidID else {
            isLoading = false
            return
        }
        
        print("KidViewModel: Carregando atividades para kid: \(currentKidID.recordName)")
        loadActivities(for: kid, using: currentKidID.zoneID)
    }
    
    private func loadActivities(for kid: Kid, using zoneID: CKRecordZone.ID) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            print("KidViewModel: ID do filho não encontrado")
            isLoading = false
            return
        }
        
        print("🔍 KidViewModel: Iniciando busca de atividades")
        print("🔍 KidViewModel: kidID procurado: \(kidID)")
        print("🔍 KidViewModel: zoneID: \(zoneID)")
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let database = UserManager.shared.isChild ? container.sharedCloudDatabase : container.privateCloudDatabase
        
        Task {
            do {
                let zones = try await database.allRecordZones()
                print("KidViewModel: Zonas disponíveis: \(zones.map { $0.zoneID.zoneName })")
                
                var allActivities: [ActivitiesRegister] = []
                
                for zone in zones {
                    print("\n🔍 KidViewModel: === TESTANDO ZONA: \(zone.zoneID.zoneName) ===")
                    
                    // Busca geral por ScheduledActivity (mesmo método da KidReceiverView)
                    do {
                        let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
                        let (results, _) = try await database.records(matching: query, inZoneWith: zone.zoneID)
                        print("KidViewModel: Encontrados \(results.count) registros ScheduledActivity")
                        
                        for (id, result) in results {
                            switch result {
                            case .success(let record):
                                print("KidViewModel: 📋 Record: \(id.recordName)")
                                print("  - Tipo: \(record.recordType)")
                                
                                let recordKidID = record["kidID"] as? String
                                let recordKidRef = record["kidReference"] as? CKRecord.Reference
                                
                                print("  - kidID: \(recordKidID ?? "nil")")
                                print("  - kidReference: \(recordKidRef?.recordID.recordName ?? "nil")")
                                print("  - Match kidID? \(recordKidID == kidID)")
                                print("  - Match kidRef? \(recordKidRef?.recordID.recordName == kidID)")
                                
                                // Verifica se pertence ao kid
                                let belongsToKid = recordKidID == kidID || recordKidRef?.recordID.recordName == kidID
                                
                                if belongsToKid {
                                    if let activity = ActivitiesRegister(record: record) {
                                        print("  - ✅ Conversão bem-sucedida!")
                                        allActivities.append(activity)
                                    } else {
                                        print("  - ❌ Falha na conversão!")
                                    }
                                }
                                
                            case .failure(let error):
                                print("KidViewModel: ❌ Erro ao processar registro: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("KidViewModel: ❌ Erro ao buscar atividades na zona \(zone.zoneID.zoneName): \(error.localizedDescription)")
                    }
                }
                
                print("\n🔍 KidViewModel: === CONCLUSÃO ===")
                if allActivities.isEmpty {
                    print("KidViewModel: ❌ Nenhuma atividade encontrada")
                } else {
                    print("KidViewModel: ✅ Encontradas \(allActivities.count) atividades")
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.processLoadedActivities(allActivities, kidID: kidID)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.handleError("Failed to load activities: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func processLoadedActivities(_ allActivities: [ActivitiesRegister], kidID: String) {
        isLoading = false
        
        if allActivities.isEmpty {
            feedbackMessage = "❌ Nenhuma atividade encontrada para este filho"
            activities = []
            return
        }
        
        activities = allActivities.sorted { $0.date < $1.date }
        
        let todayActivities = activities.filter { Calendar.current.isDateInToday($0.date) }
        
        feedbackMessage = todayActivities.isEmpty
        ? "Nenhuma atividade para hoje"
        : "✅ Encontradas \(todayActivities.count) atividades para hoje"
        
        print("📊 Total de atividades carregadas: \(activities.count)")
        print("📊 Atividades de hoje: \(todayActivities.count)")
    }
    
    func refreshActivities() {
        if let kid = kid, let currentKidID = currentKidID {
            loadActivities(for: kid, using: currentKidID.zoneID)
        } else {
            loadActivities()
        }
    }
}

// MARK: - Activity Status Management
extension KidViewModel {
    
    func updateActivityStatus(_ activity: ActivitiesRegister) {
        guard let activityID = activity.id else {
            handleError("Invalid activity ID")
            return
        }
        
        let newStatus: RegisterStatus
        switch activity.registerStatus {
        case .notStarted:
            newStatus = .inProgress
        case .inProgress:
            newStatus = .completed
        case .completed:
            return // Already completed
        }
        
        // Update locally first for immediate UI feedback
        if let index = activities.firstIndex(where: { $0.id == activityID }) {
            activities[index].registerStatus = newStatus
        }
        
        isLoading = true
        feedbackMessage = "Atualizando status da atividade..."
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let database = UserManager.shared.isChild ? container.sharedCloudDatabase : container.privateCloudDatabase
        
        Task {
            do {
                let record = try await database.record(for: activityID)
                record["status"] = newStatus.rawValue
                
                let updatedRecord = try await database.save(record)
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.feedbackMessage = "✅ Status atualizado com sucesso"
                    
                    if let updatedActivity = ActivitiesRegister(record: updatedRecord),
                       let index = self?.activities.firstIndex(where: { $0.id == activityID }) {
                        self?.activities[index] = updatedActivity
                    }
                }
            } catch let error as CKError {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    
                    // Revert local change if CloudKit update failed
                    if let index = self?.activities.firstIndex(where: { $0.id == activityID }) {
                        self?.activities[index].registerStatus = activity.registerStatus
                    }
                    
                    if error.code == .serverRecordChanged {
                        self?.handleError("Activity was modified by another device. Please refresh and try again.")
                    } else {
                        self?.handleError("Failed to update activity status: \(error.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    
                    // Revert local change if CloudKit update failed
                    if let index = self?.activities.firstIndex(where: { $0.id == activityID }) {
                        self?.activities[index].registerStatus = activity.registerStatus
                    }
                    
                    self?.handleError("Failed to update activity status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func concludedActivity(register: ActivitiesRegister) {
        updateActivityStatus(register)
    }
}

// MARK: - Data Filtering
extension KidViewModel {
    
    func registerForToday() -> [ActivitiesRegister] {
        guard let kidID = kid?.id?.recordName else { return [] }
        
        return activities
            .filter { activity in
                let belongsToKid = activity.kidID == kidID ||
                activity.kidReference?.recordID.recordName == kidID
                
                let isToday = Calendar.current.isDateInToday(activity.date)
                
                return belongsToKid && isToday
            }
            .sorted { $0.date < $1.date }
    }
    
    func notStartedRegister() -> [ActivitiesRegister] {
        registerForToday()
            .filter { $0.registerStatus == .notStarted }
    }
    
    func completedRegister() -> [ActivitiesRegister] {
        registerForToday()
            .filter { $0.registerStatus == .completed }
    }
    
    func inProgressRegister() -> [ActivitiesRegister] {
        registerForToday()
            .filter { $0.registerStatus == .inProgress }
    }
}

// MARK: - Invitation Management
extension KidViewModel {
    
    func refresh() {
        checkForSharedKid()
    }
    
    func checkForSharedKid() {
        let hasRootRecord = cloudService.getRootRecordID() != nil
        
        if hasRootRecord {
            markInvitationAsAccepted()
        }
        
        guard let rootRecordID = cloudService.getRootRecordID() else {
            feedbackMessage = "Nenhum convite aceito ainda"
            return
        }
        
        isLoading = true
        feedbackMessage = "Verificando convite aceito..."
        
        fetchKidInfo(rootRecordID: rootRecordID)
    }
    
    func markInvitationAsAccepted() {
        invitationManager.updateStatus(to: .accepted)
        hasAcceptedShareLink = true
    }
}

// MARK: - Error Handling
extension KidViewModel {
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        feedbackMessage = "❌ \(message)"
        print("KidViewModel Error: \(message)")
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
}

// MARK: - Debug
extension KidViewModel {
    var debugDescription: String {
        """
        KidViewModel Debug:
        - Current Kid ID: \(currentKidID?.recordName ?? "None")
        - Kid Name: \(kid?.name ?? "None")
        - Activities Count: \(activities.count)
        - Today's Activities: \(registerForToday().count)
        - Is Loading: \(isLoading)
        - User Role: \(UserManager.shared.userRole.rawValue)
        """
    }
}
