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
    
    // MARK: - Published Properties
    @Published var records: [ActivitiesRegister] = []
    @Published var rewards: [CollectedReward] = []
    @Published var currentDate: Date = .init()
    @Published var childName = ""
    @Published var kids: [Kid] = []
    @Published var selectedKid: Kid?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isSelectedActivity = false
    @Published var selectedActivityRegister: ActivitiesRegister?
    @Published var createNewTask = false
    @Published var feedbackMessage = ""
    @Published var sharingSheet = false
    @Published var shareView: AnyView?
    @Published var zoneReady = false
    @Published var refreshFailed: Bool = false
    
    // MARK: - Activity scheduling properties
    @Published var showActivitySelector = false
    @Published var selectedActivity: Activity?
    @Published var scheduledDate = Date()
    @Published var duration: TimeInterval = 3600 // 1 hour default
    
    // MARK: - Kid Properties
    var kidCoins: Int {
        CoinManager.shared.kidCoins
    }
    
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.debugKidRecord()
                    self.loadRewardsFromKid()
                }
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
    
    @MainActor
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
            setupCoinManager()
            return
        }
        
        cloudService.fetchAllKids { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedKids):
                self.refreshFailed = false
                self.kids = fetchedKids
                self.isLoading = false
                self.feedbackMessage = "✅ Dados atualizados"
                
            case .failure(let error):
                self.refreshFailed = true
                self.isLoading = false
                self.feedbackMessage = "❌ Erro ao carregar crianças: \(error)"
            }
        }
    }
    
    func setupCoinManager() {
        if let kidID = firstKid?.id {
            CoinManager.shared.setCurrentKid(kidID)
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
    
    func prepareKidSharing() {
        guard let kid = firstKid else { return }
        selectedKid = kid
        shareKid(kid)
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
            activityID: activity.id,
            date: scheduledDate,
            duration: duration,
            registerStatus: .notCompleted
        )
        
        cloudService.saveActivity(activityRegister) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let savedActivity):
                self.handleActivitySaveSuccess(savedActivity, for: kid, activity: activity)
                self.feedbackMessage = "✅ Atividade '\(activity.name)' agendada para \(kid.name)"
                self.showActivitySelector = false
                
                // ✅ NOVA ABORDAGEM: Atualizar currentDate se necessário
                if !Calendar.current.isDate(savedActivity.date, inSameDayAs: self.currentDate) {
                    self.currentDate = savedActivity.date
                }
                
                // ✅ NOVA ABORDAGEM: Fetch das atividades após delay
                Task {
                    // Aguarda 1 segundo para o CloudKit processar
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    await MainActor.run {
                        self.refreshActivitiesAfterSchedule(kidID: kidIDString)
                    }
                    
                    // Manter o CloudKit sharing como estava (não mexer)
                    if let shareReference = kid.shareReference {
                        await self.updateSharing(for: kid)
                    } else {
                        await self.createNewSharing(for: kid)
                    }
                }
                
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
    
    private func refreshActivitiesAfterSchedule(kidID: String) {
        print("🔄 Fazendo fetch das atividades após agendar...")
        
        CloudService.shared.fetchAllActivities(forKid: kidID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let activities):
                    self.records = activities
                    print("✅ Activities refreshed após agendar: \(activities.count) atividades")
                    
                    // Debug: quantas atividades para a data atual
                    let activitiesForCurrentDate = activities.filter {
                        Calendar.current.isDate($0.date, inSameDayAs: self.currentDate)
                    }
                    print("📅 Atividades para \(self.currentDate.format("dd/MM")): \(activitiesForCurrentDate.count)")
                    
                case .failure(let error):
                    print("❌ Erro ao refresh atividades: \(error)")
                }
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
    
    
    func loadAllActivitiesOnce() {
        guard let kidID = firstKid?.id?.recordName else {
            print("⚠️ Nenhum kid disponível para carregar atividades")
            return
        }
        
        // Evita carregar múltiplas vezes
        guard records.isEmpty || isRefreshing else {
            print("🔄 Atividades já carregadas, pulando...")
            return
        }
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        
        CloudService.shared.fetchAllActivities(forKid: kidID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let activities):
                    self.records = activities
                    self.feedbackMessage = "✅ \(activities.count) atividades carregadas"
                    print("🔍 LoadAllActivitiesOnce: Carregadas \(activities.count) atividades")
                    
                case .failure(let error):
                    self.feedbackMessage = "❌ Erro ao carregar atividades: \(error)"
                    print("❌ LoadAllActivitiesOnce: Erro - \(error)")
                }
            }
        }
    }
    
    // MARK: - Debug Operations
    
    func debugKidRecord() {
        guard let kid = firstKid,
              let record = kid.associatedRecord else {
            print("❌ Debug: Sem kid ou registro")
            return
        }
        
        print("🔍 Debug Kid Record:")
        print("  - Nome: \(kid.name)")
        print("  - ID: \(record.recordID.recordName)")
        print("  - Pending Rewards: \(record["pendingRewards"] ?? "nil")")
        print("  - Delivered Rewards: \(record["deliveredRewards"] ?? "nil")")
        print("  - Todos os campos: \(record.allKeys())")
    }
    
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
    
    
    // MARK: - Utility Operations
    
    func resetAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "rootRecordID")
        UserDefaults.standard.removeObject(forKey: "isZoneCreated")
        UserDefaults.standard.removeObject(forKey: "invitationStatus")
        UserDefaults.standard.removeObject(forKey: "currentKidRecordName")
        UserDefaults.standard.removeObject(forKey: "currentKidName")
        UserDefaults.standard.removeObject(forKey: "hasCompletedInitialSetup")
        UserDefaults.standard.synchronize()
        
        // Clear local data
        kids.removeAll()
        selectedKid = nil
        childName = ""
        InvitationStatusManager.shared.updateStatus(to: .pending)
        FirstLaunchManager.shared.reset()
        UserManager.shared.reset()
        feedbackMessage = "✅ App resetado completamente!"
    }
}

// MARK: REWARDS FUNCTIONS
extension GenitorViewModel {
    
    func loadRewardsFromKid() {
        guard let kid = firstKid else {
            print("❌ loadRewardsFromKid: Nenhuma criança encontrada")
            rewards = []
            return
        }
        
        // Primeiro, garantir que temos o registro mais atualizado
        guard let kidID = kid.id else {
            rewards = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let database = container.privateCloudDatabase
                
                // Buscar registro atualizado do Kid
                let record = try await database.record(for: kidID)
                
                let pendingRewardIDs = record["pendingRewards"] as? [Int] ?? []
                let pendingDates = record["pendingRewardDates"] as? [Date] ?? []
                let deliveredRewardIDs = record["deliveredRewards"] as? [Int] ?? []
                let deliveredDates = record["deliveredRewardDates"] as? [Date] ?? []
                
                print("📦 Recompensas pendentes: \(pendingRewardIDs.count)")
                print("📦 Recompensas entregues: \(deliveredRewardIDs.count)")
                
                var allRewards: [CollectedReward] = []
                
                // Criar CollectedRewards temporários para pendentes
                for (index, rewardID) in pendingRewardIDs.enumerated() {
                    let date = index < pendingDates.count ? pendingDates[index] : Date()
                    var reward = CollectedReward(
                        kidID: kidID.recordName,
                        rewardID: rewardID,
                        dateCollected: date,
                        isDelivered: false
                    )
                    // Criar um ID temporário para a view
                    reward.id = CKRecord.ID(recordName: "pending-\(rewardID)-\(index)")
                    allRewards.append(reward)
                }
                
                // Criar CollectedRewards temporários para entregues
                for (index, rewardID) in deliveredRewardIDs.enumerated() {
                    let date = index < deliveredDates.count ? deliveredDates[index] : Date()
                    var reward = CollectedReward(
                        kidID: kidID.recordName,
                        rewardID: rewardID,
                        dateCollected: date,
                        isDelivered: true
                    )
                    // Criar um ID temporário para a view
                    reward.id = CKRecord.ID(recordName: "delivered-\(rewardID)-\(index)")
                    allRewards.append(reward)
                }
                
                // Atualizar no main thread
                await MainActor.run {
                    self.rewards = allRewards.sorted { $0.dateCollected > $1.dateCollected }
                    self.isLoading = false
                    print("✅ Total de recompensas carregadas: \(self.rewards.count)")
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Erro ao carregar recompensas: \(error)")
                    self.rewards = []
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleRewardDeliveryStatus(_ reward: CollectedReward) {
        Task {
            do {
                guard let kid = firstKid,
                      let kidRecordID = kid.id else {
                    print("❌ Nenhuma criança selecionada")
                    return
                }
                
                let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                let database = container.privateCloudDatabase
                
                // Buscar registro atualizado
                let record = try await database.record(for: kidRecordID)
                
                var pendingRewards = record["pendingRewards"] as? [Int] ?? []
                var pendingDates = record["pendingRewardDates"] as? [Date] ?? []
                var deliveredRewards = record["deliveredRewards"] as? [Int] ?? []
                var deliveredDates = record["deliveredRewardDates"] as? [Date] ?? []
                
                if !reward.isDelivered {
                    // Mover de pendente para entregue
                    if let index = pendingRewards.firstIndex(of: reward.rewardID) {
                        pendingRewards.remove(at: index)
                        let date = index < pendingDates.count ? pendingDates[index] : Date()
                        if index < pendingDates.count {
                            pendingDates.remove(at: index)
                        }
                        
                        deliveredRewards.append(reward.rewardID)
                        deliveredDates.append(date)
                    }
                } else {
                    // Mover de entregue para pendente (desfazer entrega)
                    if let index = deliveredRewards.firstIndex(of: reward.rewardID) {
                        deliveredRewards.remove(at: index)
                        let date = index < deliveredDates.count ? deliveredDates[index] : Date()
                        if index < deliveredDates.count {
                            deliveredDates.remove(at: index)
                        }
                        
                        pendingRewards.append(reward.rewardID)
                        pendingDates.append(date)
                    }
                }
                
                // Atualizar registro
                record["pendingRewards"] = pendingRewards
                record["pendingRewardDates"] = pendingDates
                record["deliveredRewards"] = deliveredRewards
                record["deliveredRewardDates"] = deliveredDates
                
                _ = try await database.save(record)
                
                // Recarregar dados
                await MainActor.run {
                    loadRewardsFromKid()
                }
                
            } catch {
                print("❌ Erro ao atualizar status da recompensa: \(error)")
            }
        }
    }
}


// MARK: - Computed Properties Extension
extension GenitorViewModel {
    
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
    
    func clearChildName() {
        childName = ""
    }
    
    func checkShareState(for invitationStatus: InvitationStatus) -> Bool {
        return invitationStatus == .sent
    }
    
    func shouldShowShareButton(hasSharedSuccessfully: Bool) -> Bool {
        return hasKids && !hasSharedSuccessfully
    }
    
    func shouldShowShareConfirmation(hasSharedSuccessfully: Bool) -> Bool {
        return hasKids && hasSharedSuccessfully
    }
}
