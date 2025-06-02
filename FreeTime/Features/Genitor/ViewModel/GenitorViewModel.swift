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
    @Published var createNewTask = false
    @Published var feedbackMessage = ""
    @Published var sharingSheet = false
    @Published var shareView: AnyView?
    @Published var zoneReady = false
    
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
                self.kids = fetchedKids
                self.isLoading = false
                self.feedbackMessage = "✅ Dados atualizados"
                
            case .failure(let error):
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
                self.feedbackMessage = "✅ Atividade '\(activity.name)' agendada para \(kid.name)"
                self.showActivitySelector = false
                
                // Adicionar imediatamente aos records
                self.records.append(savedActivity)
                
            case .failure(let error):
                self.feedbackMessage = "❌ Erro ao agendar atividade: \(error)"
            }
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
