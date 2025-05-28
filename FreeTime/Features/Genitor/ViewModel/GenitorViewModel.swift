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
    
    @StateObject private var invitationManager = InvitationStatusManager.shared
    
    
    // MARK: - ViewModel Thales
    @Published var records: [ActivitiesRegister] = ActivitiesRegister.samples
    @Published var rewards: [CollectedReward] = CollectedReward.samples
    @Published var currentDate: Date = .init()
    
    // MARK: - Published Properties
    @Published var childName = ""
    @Published var kids: [Kid] = /*[Kid.sample]*/ []
    @Published var selectedKid: Kid?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var createNewTask = false
    @Published var feedbackMessage = ""
    @Published var sharingSheet = false
    @Published var shareView: AnyView?
    @Published var zoneReady = false
    
    // Activity scheduling properties
    @Published var showActivitySelector = false
    @Published var selectedActivity: Activity?
    @Published var scheduledDate = Date()
    @Published var duration: TimeInterval = 3600 // 1 hour default
    
    var uniqueDates: [Date] {
        Array(Set(rewards.map { $0.dateCollected.startOfDay })).sorted(by: { $1 < $0})
    }
    
    var groupedRewardsByDay: [RewardsByDay] {
        var groupAux: [RewardsByDay] = []

        for date in uniqueDates {
            var rewardsAux: [CollectedReward] = []

            for reward in self.rewards {
                if reward.dateCollected.startOfDay == date {
                    rewardsAux.append(reward)
                }
            }

            let group = RewardsByDay(date: date, rewards: rewardsAux)
            groupAux.append(group)
        }

        return groupAux
    }
    
    // MARK: - Private Properties
    
    private let cloudService = CloudService.shared
    private let container = CKContainer(identifier: CloudConfig.containerIdentifier)
    private var privateDB: CKDatabase {
        container.privateCloudDatabase
    }
    private var sharedDB: CKDatabase {
        container.sharedCloudDatabase
    }
    
    // MARK: - CloudKit Setup & Initialization
    
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
    
    // MARK: - Kid Management Operations
    
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
        
        CloudService.shared.saveKid(kid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedKid):
                    self?.kids.append(savedKid)
                    self?.childName = ""
                    self?.feedbackMessage = "✅ \(savedKid.name) foi adicionado com sucesso!"
                    
                    // Define o usuário como pai e salva o Kid completo
                    UserManager.shared.setAsParent(withKid: savedKid)
                    
                case .failure(let error):
                    self?.feedbackMessage = "❌ Erro ao adicionar criança: \(error.localizedDescription)"
                }
                self?.isLoading = false
            }
        }
    }
    
    private func loadKids() {
        isLoading = true
        feedbackMessage = "Carregando suas crianças do CloudKit..."
        
        Task {
            // Wait for 1 second before checking CloudKit
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
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
    }
    
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
    
    // MARK: - Sharing Operations
    
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
    
    // MARK: - Activity Management Operations
    
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
            activityID: activity.id, // Agora activity.id é Int
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
    
    // MARK: - Utility & Reset Operations
    
    func resetAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "rootRecordID")
        UserDefaults.standard.removeObject(forKey: "isZoneCreated")
        UserDefaults.standard.removeObject(forKey: "invitationStatus")
        UserDefaults.standard.removeObject(forKey: "currentKidRecordName")
        UserDefaults.standard.removeObject(forKey: "currentKidName")
        UserDefaults.standard.removeObject(forKey: "hasCompletedInitialSetup") // Nova linha
        UserDefaults.standard.synchronize()
        
        // Clear local data
        kids.removeAll()
        selectedKid = nil
        childName = ""
        InvitationStatusManager.shared.updateStatus(to: .pending)
        FirstLaunchManager.shared.reset() // Nova linha
        UserManager.shared.reset()
        feedbackMessage = "✅ App resetado completamente!"
    }
    
    // MARK: - Debug Operations
    
    func debugSharedDatabase() {
        Task {
            await performDebugSharedDatabase()
            await performDebugSharedFromParent()
        }
    }
    
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

// MARK: - Kid Management Extension
extension GenitorViewModel {
    
    // MARK: - Computed Properties
    
    var hasKids: Bool {
        !kids.isEmpty
    }
    
    var firstKid: Kid? {
        kids.first
    }
    
    var canAddChild: Bool {
        !childName.isEmpty && !isLoading && zoneReady
    }
    
    var canShareKid: Bool {
        !isLoading && firstKid != nil
    }
    
    // MARK: - Kid Management Methods
    
    func prepareKidSharing() {
        guard let kid = firstKid else { return }
        selectedKid = kid
        shareKid(kid)
    }
    
    func clearChildName() {
        childName = ""
    }
    
    // MARK: - State Check Methods
    
    func checkShareState(for invitationStatus: InvitationStatus) -> Bool {
        // Verifica se já existe um compartilhamento com base no status do convite
        return invitationStatus == .sent
    }
    
    func shouldShowShareButton(hasSharedSuccessfully: Bool) -> Bool {
        return hasKids && !hasSharedSuccessfully
    }
    
    func shouldShowShareConfirmation(hasSharedSuccessfully: Bool) -> Bool {
        return hasKids && hasSharedSuccessfully
    }
    
    // MARK: - Debug Info
    
    var debugInfo: [(label: String, value: String)] {
        [
            ("Zone Ready", zoneReady ? "Yes" : "No"),
            ("Kids Count", "\(kids.count)"),
            ("Is Loading", isLoading ? "Yes" : "No"),
            ("Has Share View", shareView != nil ? "Yes" : "No")
        ]
    }
}
