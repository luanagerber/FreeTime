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
    @Published var isLoading = false
    @Published var feedbackMessage = ""
    @Published var kid: Kid?
    //    @Published var activities: [ActivitiesRegister] = []
    @Published var activitiesRegister: [ActivitiesRegister] = ActivitiesRegister.samples
    
    // MARK: - Private Properties
    private let cloudService = CloudService.shared
    private let container = CKContainer(identifier: CloudConfig.containerIndentifier)
    private var sharedDB: CKDatabase {
        container.sharedCloudDatabase
    }
    
    // MARK: - Public LOCAL Methods
    func registerForToday(kidID: String) -> [ActivitiesRegister] {
        activitiesRegister
            .filter { $0.kidID == kidID && Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    func notStartedRegister(kidID: String) -> [ActivitiesRegister] {
        registerForToday(kidID: kidID)
            .filter { $0.registerStatus == .notStarted }
    }
    
    func completedRegister(kidID: String) -> [ActivitiesRegister] {
        registerForToday(kidID: kidID)
            .filter { $0.registerStatus == .completed }
    }
    
    func concludedActivity(register: ActivitiesRegister) {
        if let index = self.activitiesRegister.firstIndex(where: { $0.id == register.id }) {
            self.activitiesRegister[index].registerStatus = .completed
        }
    }
    
    
    // MARK: - Public CLOUD Methods
    func refresh() {
        checkForSharedKid()
    }
    
    func checkForSharedKid() {
        guard let rootRecordID = cloudService.getRootRecordID() else {
            feedbackMessage = "Nenhum convite aceito ainda"
            return
        }
        
        isLoading = true
        feedbackMessage = "Verificando convite aceito..."
        
        fetchKidInfo(rootRecordID: rootRecordID)
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
                   let index = activitiesRegister.firstIndex(where: { $0.id == activityID }) {
                    activitiesRegister[index] = updatedActivity
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
                
                processLoadedActivities(allActivities)
            } catch {
                print("❌ Erro geral: \(error.localizedDescription)")
                isLoading = false
                feedbackMessage = "❌ Erro ao carregar atividades: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchActivitiesInZone(_ zoneID: CKRecordZone.ID, kidID: String) async -> [ActivitiesRegister] {
        var activities: [ActivitiesRegister] = []
        
        do {
            let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
            let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zoneID)
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let activity = ActivitiesRegister(record: record) {
                        activities.append(activity)
                    }
                case .failure(let error):
                    print("❌ Erro ao processar registro: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Erro ao buscar atividades na zona \(zoneID.zoneName): \(error.localizedDescription)")
        }
        
        return activities
    }
    
    private func processLoadedActivities(_ allActivities: [ActivitiesRegister]) {
        isLoading = false
        
        if allActivities.isEmpty {
            feedbackMessage = "❌ Nenhuma atividade no banco compartilhado"
            activitiesRegister = []
            return
        }
        
        // Filter activities for today
        let calendar = Calendar.current
        activitiesRegister = allActivities.filter { activity in
            calendar.isDateInToday(activity.date)
        }
        
        feedbackMessage = activitiesRegister.isEmpty
        ? "Nenhuma atividade para hoje"
        : "✅ Encontradas \(activitiesRegister.count) atividades para hoje"
    }
    
}
