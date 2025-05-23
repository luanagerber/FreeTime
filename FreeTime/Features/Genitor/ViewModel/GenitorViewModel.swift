//
//  GenitorViewModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI
import CloudKit
import Combine


@MainActor
class GenitorViewModel: ObservableObject {
    
    static let shared = GenitorViewModel()
    
    // MARK: - ViewModel Thales
    @Published var records: [ActivitiesRegister] = ActivitiesRegister.samples
    @Published var rewards: [CollectedReward] = []
    @Published var currentDate: Date = .init()
    
    // MARK: - Published Properties
    @Published var childName = ""
    @Published var kids: [Kid] = []
    @Published var selectedKid: Kid?
    @Published var isLoading = false
    @Published var feedbackMessage = ""
    @Published var sharingSheet = false
    @Published var shareView: AnyView?
    @Published var zoneReady = false
    
    // Activity scheduling properties
    @Published var showActivitySelector = false
    @Published var selectedActivity: Activity?
    @Published var scheduledDate = Date()
    @Published var duration: TimeInterval = 3600 // 1 hour default
    
    // MARK: - Private Properties
    
    private let cloudService = CloudService.shared
    private let container = CKContainer(identifier: CloudConfig.containerIdentifier)
    private var privateDB: CKDatabase {
        container.privateCloudDatabase
    }
    private var sharedDB: CKDatabase {
        container.sharedCloudDatabase
    }
    
    // MARK: - Initialization
    func setupCloudKit() {
        feedbackMessage = "Configurando CloudKit..."
        isLoading = true
        
        Task {
            do {
                try await cloudService.createZoneIfNeeded()
                print("✅ Zona Kids criada ou verificada")
                
                zoneReady = true
                feedbackMessage = "✅ CloudKit configurado com sucesso"
                loadKids()
            } catch {
                await handleZoneCreationError(error)
            }
        }
    }
    
    // MARK: - Public Methods
    func refresh() {
        isLoading = true
        feedbackMessage = "Atualizando dados..."
        
        if !zoneReady {
            setupCloudKit()
            return
        }
        
        cloudService.fetchAllKids { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedKids):
                self.kids = fetchedKids
                
                if let selectedKid = self.selectedKid,
                   let kidID = selectedKid.id?.recordName,
                   !fetchedKids.isEmpty {
                    self.loadSharedActivities(for: kidID)
                } else {
                    self.isLoading = false
                    self.feedbackMessage = fetchedKids.isEmpty
                    ? "Nenhuma criança encontrada no CloudKit"
                    : "✅ Carregadas \(fetchedKids.count) crianças"
                }
                
            case .failure(let error):
                self.isLoading = false
                self.feedbackMessage = "❌ Erro ao carregar crianças: \(error)"
            }
        }
    }
    
    func addChild() {
        guard !childName.isEmpty else { return }
        
        isLoading = true
        feedbackMessage = "Adicionando criança ao CloudKit..."
        
        let kid = Kid(name: childName)
        
        guard kid.record != nil else {
            isLoading = false
            feedbackMessage = "❌ Erro: Falha ao criar registro da criança"
            return
        }
        
        cloudService.saveKid(kid) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let newKid):
                self.feedbackMessage = "✅ Adicionado com sucesso \(newKid.name) ao CloudKit"
                self.childName = ""
                self.loadKids()
            case .failure(let error):
                self.feedbackMessage = "❌ Erro ao adicionar criança: \(error)"
            }
        }
    }
    
    func scheduleActivity() {
        guard let kid = selectedKid,
              let activity = selectedActivity,
              let kidIDString = kid.id?.recordName else {
            feedbackMessage = "❌ Erro: Dados incompletos para agendar atividade"
            return
        }
        
        isLoading = true
        feedbackMessage = "Agendando atividade para \(kid.name)..."
        
        let activityRegister = ActivitiesRegister(
            kid: kid,
            activityID: activity.id,
            date: scheduledDate,
            duration: duration,
            registerStatus: .notStarted
        )
        
        cloudService.saveActivity(activityRegister) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let savedActivity):
                self.handleActivitySaveSuccess(savedActivity, for: kid, activity: activity)
            case .failure(let error):
                self.feedbackMessage = "❌ Erro ao agendar atividade: \(error)"
            }
        }
    }
    
    func shareKid(_ kid: Kid) {
        isLoading = true
        feedbackMessage = "Gerando link de compartilhamento para \(kid.name)..."
        
        Task {
            do {
                try await cloudService.shareKid(kid) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch result {
                    case .success(let view):
                        self.shareView = AnyView(view)
                        self.feedbackMessage = "✅ Compartilhamento preparado para \(kid.name)"
                        self.sharingSheet = true
                    case .failure(let error):
                        self.feedbackMessage = "❌ Erro ao compartilhar criança: \(error)"
                    }
                }
            } catch {
                isLoading = false
                feedbackMessage = "❌ Erro: \(error.localizedDescription)"
            }
        }
    }
    
    func resetAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "rootRecordID")
        UserDefaults.standard.removeObject(forKey: "isZoneCreated")
        UserDefaults.standard.synchronize()
        
        // Clear local data
        kids.removeAll()
        selectedKid = nil
        childName = ""
        feedbackMessage = "✅ App resetado completamente!"
    }
    
    // MARK: - Debug Methods
    func debugSharedDatabase() {
        Task {
            await performDebugSharedDatabase()
            await performDebugSharedFromParent()
        }
    }
    
    // MARK: - Private Methods
    private func loadKids() {
        isLoading = true
        feedbackMessage = "Carregando suas crianças do CloudKit..."
        
        cloudService.fetchAllKids { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let fetchedKids):
                self.kids = fetchedKids
                self.feedbackMessage = fetchedKids.isEmpty
                ? "Nenhuma criança encontrada no CloudKit"
                : "✅ Carregadas \(fetchedKids.count) crianças"
            case .failure(let error):
                self.feedbackMessage = "❌ Erro ao carregar crianças: \(error)"
            }
        }
    }
    
    private func handleZoneCreationError(_ error: Error) async {
        if let ckError = error as? CKError, ckError.code == .zoneNotFound {
            print("📋 Tentando criar zona novamente em 2 segundos...")
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            do {
                try await cloudService.createZoneIfNeeded()
                zoneReady = true
                feedbackMessage = "✅ CloudKit configurado com sucesso (segunda tentativa)"
                loadKids()
            } catch {
                isLoading = false
                feedbackMessage = "❌ Erro crítico ao configurar CloudKit. Por favor, reinicie o aplicativo."
            }
        } else {
            isLoading = false
            feedbackMessage = "❌ Erro: \(error.localizedDescription)"
        }
    }
    
    private func handleActivitySaveSuccess(_ savedActivity: ActivitiesRegister, for kid: Kid, activity: Activity) {
        feedbackMessage = "✅ Atividade '\(activity.name)' agendada para \(kid.name)"
        showActivitySelector = false
        
        Task {
            if let shareReference = kid.shareReference {
                print("🔄 Forçando re-compartilhamento para incluir nova atividade...")
                await updateSharing(for: kid)
            } else {
                print("Criança não tem compartilhamento ainda, criando...")
                await createNewSharing(for: kid)
            }
            
            // Debug verification after delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await verifyActivityInSharedDatabase(savedActivity, kid: kid)
        }
    }
    
    private func updateSharing(for kid: Kid) async {
        do {
            try await cloudService.shareKid(kid) { result in
                switch result {
                case .success:
                    print("✅ Re-compartilhamento bem-sucedido!")
                case .failure(let error):
                    print("❌ Erro no re-compartilhamento: \(error)")
                }
            }
        } catch {
            print("❌ Erro ao re-compartilhar: \(error)")
        }
    }
    
    private func createNewSharing(for kid: Kid) async {
        do {
            try await cloudService.shareKid(kid) { [weak self] result in
                switch result {
                case .success:
                    print("✅ Compartilhamento criado após nova atividade")
                    self?.refresh()
                case .failure(let error):
                    print("❌ Erro ao criar compartilhamento: \(error)")
                }
            }
        } catch {
            print("❌ Erro ao criar compartilhamento: \(error)")
        }
    }
    
    private func loadSharedActivities(for kidID: String) {
        cloudService.fetchSharedActivities(forKid: kidID) { [weak self] (result: Result<[ActivitiesRegister], CloudError>) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let sharedActivities):
                if !sharedActivities.isEmpty {
                    self.syncActivitiesWithPrivateDB(sharedActivities, kidID: kidID)
                } else {
                    self.feedbackMessage = "✅ Dados atualizados"
                }
            case .failure:
                self.feedbackMessage = "✅ Dados atualizados"
            }
        }
    }
    
    private func syncActivitiesWithPrivateDB(_ sharedActivities: [ActivitiesRegister], kidID: String) {
        cloudService.fetchAllActivities(forKid: kidID) { [weak self] (result: Result<[ActivitiesRegister], CloudError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let privateActivities):
                var activitiesToUpdate: [ActivitiesRegister] = []
                
                for sharedActivity in sharedActivities {
                    if let privateVersion = privateActivities.first(where: { $0.activityID == sharedActivity.activityID }),
                       privateVersion.registerStatus != sharedActivity.registerStatus {
                        var updatedActivity = privateVersion
                        updatedActivity.registerStatus = sharedActivity.registerStatus
                        activitiesToUpdate.append(updatedActivity)
                    }
                }
                
                if !activitiesToUpdate.isEmpty {
                    self.updatePrivateActivities(activitiesToUpdate)
                } else {
                    self.feedbackMessage = "✅ Dados atualizados - Tudo sincronizado"
                }
                
            case .failure:
                self.feedbackMessage = "✅ Dados atualizados, mas falha ao sincronizar atividades"
            }
        }
    }
    
    private func updatePrivateActivities(_ activities: [ActivitiesRegister]) {
        let dispatchGroup = DispatchGroup()
        var updatedCount = 0
        
        for activity in activities {
            dispatchGroup.enter()
            
            cloudService.updateActivity(activity, isShared: false) { result in
                if case .success = result {
                    updatedCount += 1
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.feedbackMessage = "✅ Dados atualizados - \(updatedCount) atividades sincronizadas"
        }
    }
    
    // MARK: - Debug Helper Methods
    private func performDebugSharedDatabase() async {
        print("🔍 PAI: Verificando banco compartilhado...")
        
        do {
            let zones = try await sharedDB.allRecordZones()
            print("🔍 PAI: Zonas no banco compartilhado: \(zones.map { $0.zoneID.zoneName })")
            
            for zone in zones {
                let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
                let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                print("🔍 PAI: ScheduledActivity na zona \(zone.zoneID.zoneName): \(results.count)")
                
                for (id, result) in results {
                    switch result {
                    case .success(let record):
                        print("🔍 PAI: Atividade encontrada: \(id.recordName)")
                        print("  - kidID: \(record["kidID"] ?? "nil")")
                        print("  - activityID: \(record["activityID"] ?? "nil")")
                        print("  - status: \(record["status"] ?? "nil")")
                    case .failure(let error):
                        print("🔍 PAI: Erro: \(error)")
                    }
                }
            }
        } catch {
            print("🔍 PAI: Erro ao verificar: \(error)")
        }
    }
    
    private func performDebugSharedFromParent() async {
        print("🔍 PAI: Verificando banco compartilhado do lado do pai...")
        
        do {
            let zones = try await sharedDB.allRecordZones()
            print("🔍 PAI: Zonas compartilhadas: \(zones.map { $0.zoneID.zoneName })")
            
            for zone in zones {
                for recordType in ["Kid", "ScheduledActivity"] {
                    let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                    let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                    print("🔍 PAI: \(recordType) na zona \(zone.zoneID.zoneName): \(results.count)")
                }
            }
        } catch {
            print("🔍 PAI: Erro: \(error)")
        }
    }
    
    private func verifyActivityInSharedDatabase(_ activity: ActivitiesRegister, kid: Kid) async {
        print("🔍 VERIFICAÇÃO: Atividade deveria estar no banco compartilhado agora...")
        
        do {
            let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
            let zones = try await sharedDB.allRecordZones()
            
            for zone in zones {
                let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                print("🔍 VERIFICAÇÃO: Zona \(zone.zoneID.zoneName): \(results.count) atividades")
            }
        } catch {
            print("🔍 VERIFICAÇÃO: Erro: \(error)")
        }
    }
    
}
