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
        
        cloudService.fetchKid(withRecordID: kidID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let kid):
                    print("KidViewModel: Kid compartilhado encontrado")
                    self?.kid = kid
                    self?.loadActivities()
                case .failure(let error):
                    print("KidViewModel: Falha ao carregar kid compartilhado: \(error)")
                    self?.handleError("Failed to load shared kid: \(error.localizedDescription)")
                    self?.isLoading = false
                }
            }
        }
    }
    
    func loadFromRootRecord() {
        guard let rootRecordID = cloudService.getRootRecordID() else {
            handleError("No shared kid found")
            return
        }
        
        self.currentKidID = rootRecordID
        loadSharedKidData()
    }
}

// MARK: - Activities Management
extension KidViewModel {
    
    private func loadActivities() {
        guard let kidID = currentKidID else {
            isLoading = false
            return
        }
        
        print("KidViewModel: Carregando atividades para kid: \(kidID.recordName)")
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let database = UserManager.shared.isChild ? container.sharedCloudDatabase : container.privateCloudDatabase
        
        Task {
            do {
                let zones = try await database.allRecordZones()
                var allActivities: [ActivitiesRegister] = []
                
                for zone in zones {
                    let activities = await fetchActivitiesInZone(zone.zoneID, kidID: kidID.recordName, database: database)
                    allActivities.append(contentsOf: activities)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.processLoadedActivities(allActivities, kidID: kidID.recordName)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.handleError("Failed to load activities: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchActivitiesInZone(_ zoneID: CKRecordZone.ID, kidID: String, database: CKDatabase) async -> [ActivitiesRegister] {
        var fetchedActivities: [ActivitiesRegister] = []
        
        do {
            let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let activity = ActivitiesRegister(record: record) {
                        let belongsToKid = activity.kidID == kidID ||
                        activity.kidReference?.recordID.recordName == kidID
                        
                        if belongsToKid {
                            fetchedActivities.append(activity)
                        }
                    }
                case .failure(let error):
                    print("❌ Erro ao processar registro: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Erro ao buscar atividades na zona \(zoneID.zoneName): \(error.localizedDescription)")
        }
        
        return fetchedActivities
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
        loadActivities()
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
                        self?.loadActivities()
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
