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
    
    //    @EnvironmentObject var coordinator: Coordinator
    //    private var cloudService: CloudService = .shared
    //    let kidId: CKRecord.ID? = nil
    //
    //    @Published var kid: Kid = Kid.sample
    //    @Published var register: [ActivitiesRegister] = ActivitiesRegister.samples
    
    @EnvironmentObject var coordinator: Coordinator
    @StateObject private var invitationManager = InvitationStatusManager.shared
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var hasAcceptedShareLink = false
    @Published var feedbackMessage = ""
    @Published var kid: Kid?
    @Published var activities: [ActivitiesRegister] = []
    
    // MARK: - Private Properties
    private let cloudService = CloudService.shared
    private let container = CKContainer(identifier: CloudConfig.containerIdentifier)
    private var sharedDB: CKDatabase {
        container.sharedCloudDatabase
    }
    
    // MARK: - Public LOCAL Methods
    func registerForToday() -> [ActivitiesRegister] {
        guard let kidID = kid?.id?.recordName else { return [] }
        
        return activities
            .filter { activity in
                // Check if activity belongs to this kid
                let belongsToKid = activity.kidID == kidID ||
                activity.kidReference?.recordID.recordName == kidID
                
                // Check if activity is for today
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
    
    func concludedActivity(register: ActivitiesRegister) {
        guard let activityID = register.id else { return }
        
        // Update locally first for immediate UI feedback
        if let index = activities.firstIndex(where: { $0.id == activityID }) {
            activities[index].registerStatus = .completed
        }
        
        // Then update in CloudKit
        updateActivityStatus(register)
    }
    
    // MARK: - Public CLOUD Methods
    func refresh() {
        checkForSharedKid()
    }
    
    func checkForSharedKid() {
        // Check if we have a root record ID (invitation accepted)
        let hasRootRecord = cloudService.getRootRecordID() != nil
        
        if hasRootRecord {
            // Update invitation status to accepted
            markInvitationAsAccepted()
        }
        
        guard let rootRecordID = cloudService.getRootRecordID() else {
            feedbackMessage = "Nenhum convite aceito ainda"
            // Keep current status if no root record (could be pending or sent)
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
    
    func updateActivityStatus(_ activity: ActivitiesRegister) {
        guard let activityID = activity.id else {
            feedbackMessage = "ID da atividade não encontrado"
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
        
        isLoading = true
        feedbackMessage = "Atualizando status da atividade..."
        
        Task {
            do {
                let record = try await sharedDB.record(for: activityID)
                record["status"] = newStatus.rawValue
                
                let updatedRecord = try await sharedDB.save(record)
                
                isLoading = false
                feedbackMessage = "✅ Status atualizado com sucesso"
                
                if let updatedActivity = ActivitiesRegister(record: updatedRecord),
                   let index = activities.firstIndex(where: { $0.id == activityID }) {
                    activities[index] = updatedActivity
                }
            } catch {
                print("❌ Erro ao atualizar status: \(error.localizedDescription)")
                isLoading = false
                feedbackMessage = "❌ Erro ao atualizar status: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private CLOUD Methods
    private func fetchKidInfo(rootRecordID: CKRecord.ID) {
        Task {
            do {
                let record = try await sharedDB.record(for: rootRecordID)
                print("✅ Registro compartilhado encontrado: \(record.recordID.recordName)")
                
                if let fetchedKid = Kid(record: record) {
                    kid = fetchedKid
                    feedbackMessage = "✅ Conectado como \(fetchedKid.name)"
                    loadActivities(for: fetchedKid, using: record.recordID.zoneID)
                } else {
                    print("❌ Falha ao converter o registro para Kid")
                    isLoading = false
                    feedbackMessage = "❌ Erro ao carregar informações do registro compartilhado"
                }
            } catch {
                print("❌ Erro ao acessar registro compartilhado: \(error.localizedDescription)")
                isLoading = false
                feedbackMessage = "❌ Erro ao carregar convite: \(error)"
            }
        }
    }
    
    private func loadActivities(for kid: Kid, using zoneID: CKRecordZone.ID) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            isLoading = false
            return
        }
        
        print("🔍 Iniciando busca de atividades para kidID: \(kidID)")
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        
        Task {
            do {
                let zones = try await sharedDB.allRecordZones()
                var allActivities: [ActivitiesRegister] = []
                
                for zone in zones {
                    let activities = await fetchActivitiesInZone(zone.zoneID, kidID: kidID)
                    allActivities.append(contentsOf: activities)
                }
                
                processLoadedActivities(allActivities, kidID: kidID)
            } catch {
                print("❌ Erro geral: \(error.localizedDescription)")
                isLoading = false
                feedbackMessage = "❌ Erro ao carregar atividades: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchActivitiesInZone(_ zoneID: CKRecordZone.ID, kidID: String) async -> [ActivitiesRegister] {
        var fetchedActivities: [ActivitiesRegister] = []
        
        do {
            let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
            let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zoneID)
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let activity = ActivitiesRegister(record: record) {
                        // Check if this activity belongs to this kid
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
        
        // Store all activities (not just today's)
        activities = allActivities.sorted { $0.date < $1.date }
        
        // Count today's activities for feedback
        let todayActivities = activities.filter { Calendar.current.isDateInToday($0.date) }
        
        feedbackMessage = todayActivities.isEmpty
        ? "Nenhuma atividade para hoje"
        : "✅ Encontradas \(todayActivities.count) atividades para hoje"
        
        print("📊 Total de atividades carregadas: \(activities.count)")
        print("📊 Atividades de hoje: \(todayActivities.count)")
    }
}
