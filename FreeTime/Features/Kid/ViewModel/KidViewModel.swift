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
    @Published var kid: Kid? {
        didSet {
            print("🔄 Kid atualizado: \(kid?.name ?? "nil")")
            
            // ✅ Para o observer uma vez que o kid é carregado
            if kid != nil {
                stopUserManagerObserver()
            }
            
            // Publica que o kid mudou para triggerar onReceive
            kidDidChange.send(kid)
        }
    }

    @Published var activities: [ActivitiesRegister] = []
    @Published var isLoading = false
    @Published var isLoadingActivities = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var feedbackMessage = ""
    @Published var hasAcceptedShareLink = false
    
    // ✅ NOVO: Publisher para comunicar mudanças no kid
    let kidDidChange = PassthroughSubject<Kid?, Never>()
    
    // ✅ NOVO: Cancellables para observar UserManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Other Properties
    private let cloudService = CloudService.shared
    private let invitationManager = InvitationStatusManager.shared
    
    var currentKidID: CKRecord.ID?
    
    var kidName: String? {
        return UserManager.shared.currentKidName
    }
    
    var kidCoins: Int {
        CoinManager.shared.kidCoins
    }
    
    // MARK: - Initialization
    init() {
        loadFromUserManager()
        setupUserManagerObserver()
    }
    
    func loadTestActivities() {
        activities = [
            ActivitiesRegister(kid: Kid.sample, activityID: 1, date: Date(), duration: TimeInterval())]
    }
    
    // ✅ NOVO: Observer para mudanças no UserManager
       private func setupUserManagerObserver() {
           // Observa mudanças no UserManager a cada 0.5 segundos
           Timer.publish(every: 0.5, on: .main, in: .common)
               .autoconnect()
               .sink { [weak self] _ in
                   self?.checkForUserManagerUpdates()
               }
               .store(in: &cancellables)
           
           print("🔄 Observer do UserManager configurado")
       }
       
       // ✅ NOVO: Verifica se UserManager teve mudanças
       private func checkForUserManagerUpdates() {
           let userManager = UserManager.shared
           
           // ✅ Se já temos um kid carregado, para o observer
           if kid != nil {
               print("🔄 OBSERVER: Kid já carregado (\(kid?.name ?? "unknown")), parando observer...")
               stopUserManagerObserver()
               return
           }
           
           // Se não temos kid carregado mas UserManager agora tem um
           if userManager.hasValidKid {
               print("🔄 OBSERVER: UserManager agora tem kid válido, recarregando...")
               print("🔄 OBSERVER: Kid name: \(userManager.currentKidName)")
               print("🔄 OBSERVER: Is child: \(userManager.isChild)")
               
               loadFromUserManager()
           }
       }
       
       // ✅ NOVO: Para o observer do UserManager
       private func stopUserManagerObserver() {
           cancellables.removeAll()
           print("🔄 Observer do UserManager parado - kid carregado com sucesso")
       }
       
       private func loadFromUserManager() {
           let userManager = UserManager.shared
           
           print("🔄 LOAD: Carregando dados do UserManager")
           print("🔄 LOAD: UserManager hasValidKid: \(userManager.hasValidKid)")
           print("🔄 LOAD: UserManager isChild: \(userManager.isChild)")
           print("🔄 LOAD: UserManager currentKidName: \(userManager.currentKidName)")
           
           // Se o UserManager tem um kid válido, use-o
           if let kidID = userManager.currentKidID {
               print("🔄 LOAD: Kid encontrado - ID: \(kidID.recordName), Nome: \(userManager.currentKidName)")
               print("🔄 LOAD: Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
               self.currentKidID = kidID
               
               // Carrega dados baseado no tipo de usuário
               if userManager.isChild {
                   print("🔄 LOAD: Carregando como criança (dados compartilhados)")
                   loadChildKidOnly()
               } else {
                   print("🔄 LOAD: Carregando como pai (dados privados)")
                   loadKidDataOnly()
               }
           } else if let rootRecordID = CloudService.shared.getRootRecordID() {
               // Fallback para o método antigo se necessário
               print("🔄 LOAD: Usando fallback rootRecordID")
               self.currentKidID = rootRecordID
               loadChildKidOnly()
           } else {
               print("🔄 LOAD: ❌ Nenhum kid encontrado!")
           }
       }
}
    

// MARK: - Kid Management
extension KidViewModel {
    
    // ✅ NOVO: Carrega só o kid (sem atividades) - versão pai
       private func loadKidDataOnly() {
           guard let kidID = currentKidID else {
               print("KidViewModel: loadKidDataOnly - Nenhum kidID definido")
               return
           }
           
           print("KidViewModel: Carregando APENAS kid: \(kidID.recordName)")
           isLoading = true
           
           let container = CKContainer(identifier: CloudConfig.containerIdentifier)
           let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
           let isChildUser = UserManager.shared.isChild
           
           let database = (isSharedZone || isChildUser) ?
                          container.sharedCloudDatabase :
                          container.privateCloudDatabase
           
           Task {
               do {
                   let record = try await database.record(for: kidID)
                   print("✅ KidViewModel: Kid carregado (só dados básicos)")
                   
                   DispatchQueue.main.async { [weak self] in
                       self?.isLoading = false
                       if let kid = Kid(record: record) {
                           self?.kid = kid // ✅ Isto vai triggerar o didSet e o Publisher
                       } else {
                           self?.handleError("Failed to convert record to Kid")
                       }
                   }
               } catch {
                   DispatchQueue.main.async { [weak self] in
                       print("❌ KidViewModel: Erro ao carregar kid: \(error)")
                       self?.isLoading = false
                       self?.handleError("Failed to load kid data: \(error.localizedDescription)")
                   }
               }
           }
       }
       
       // ✅ NOVO: Carrega só o kid (sem atividades) - versão criança
       private func loadChildKidOnly() {
           guard let kidID = currentKidID else {
               print("KidViewModel: loadChildKidOnly - Nenhum kidID definido")
               return
           }
           
           print("KidViewModel: Carregando APENAS dados da criança: \(kidID.recordName)")
           isLoading = true
           
           let container = CKContainer(identifier: CloudConfig.containerIdentifier)
           
           Task {
               do {
                   let sharedDB = container.sharedCloudDatabase
                   let record = try await sharedDB.record(for: kidID)
                   print("✅ KidViewModel: Kid criança carregado do banco compartilhado")
                   
                   DispatchQueue.main.async { [weak self] in
                       self?.isLoading = false
                       if let kid = Kid(record: record) {
                           self?.kid = kid // ✅ Isto vai triggerar o didSet e o Publisher
                       } else {
                           self?.handleError("Failed to convert shared record to Kid")
                       }
                   }
               } catch {
                   print("❌ KidViewModel: Falha no banco compartilhado: \(error)")
                   
                   // Fallback para banco privado
                   do {
                       let privateDB = container.privateCloudDatabase
                       let record = try await privateDB.record(for: kidID)
                       print("✅ KidViewModel: Kid encontrado no banco privado")
                       
                       DispatchQueue.main.async { [weak self] in
                           self?.isLoading = false
                           if let kid = Kid(record: record) {
                               self?.kid = kid // ✅ Isto vai triggerar o didSet e o Publisher
                           } else {
                               self?.handleError("Failed to convert private record to Kid")
                           }
                       }
                   } catch {
                       DispatchQueue.main.async { [weak self] in
                           print("❌ KidViewModel: Falha em ambos os bancos: \(error)")
                           self?.isLoading = false
                           self?.handleError("Failed to load kid from both databases: \(error.localizedDescription)")
                       }
                   }
               }
           }
       }
    
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
        print("KidViewModel: Zone ID: \(kidID.zoneID)")
        print("KidViewModel: Zone Owner: \(kidID.zoneID.ownerName)")
        isLoading = true
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        // CORREÇÃO: Determinar qual banco usar baseado no owner da zona E no role do usuário
        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
        let isChildUser = UserManager.shared.isChild
        
        print("KidViewModel: isSharedZone: \(isSharedZone), isChildUser: \(isChildUser)")
        
        // Para crianças, SEMPRE usar banco compartilhado se a zona for compartilhada
        let database = (isSharedZone || isChildUser) ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        print("KidViewModel: Usando \((isSharedZone || isChildUser) ? "banco compartilhado" : "banco privado")")
        
        Task {
            do {
                let record = try await database.record(for: kidID)
                print("✅ KidViewModel: Kid encontrado")
                
                DispatchQueue.main.async { [weak self] in
                    if let kid = Kid(record: record) {
                        self?.kid = kid
                        self?.loadActivities(for: kid, using: record.recordID.zoneID)
                    } else {
                        self?.isLoading = false
                        self?.handleError("Failed to convert record to Kid")
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("❌ KidViewModel: Erro ao carregar kid: \(error)")
                    self?.isLoading = false
                    self?.handleError("Failed to load kid data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadChildData() {
        guard let kidID = currentKidID else {
            print("KidViewModel: loadChildData - Nenhum kidID definido")
            return
        }
        
        print("KidViewModel: Carregando dados da criança: \(kidID.recordName)")
        print("KidViewModel: Zone ID: \(kidID.zoneID)")
        isLoading = true
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        // Para crianças, tenta primeiro o banco compartilhado
        print("KidViewModel: Tentando banco compartilhado primeiro...")
        
        Task {
            do {
                let sharedDB = container.sharedCloudDatabase
                let record = try await sharedDB.record(for: kidID)
                print("✅ KidViewModel: Kid encontrado no banco compartilhado")
                
                DispatchQueue.main.async { [weak self] in
                    if let kid = Kid(record: record) {
                        self?.kid = kid
                        self?.loadActivitiesFromSharedDB(for: kid)
                    } else {
                        self?.isLoading = false
                        self?.handleError("Failed to convert shared record to Kid")
                    }
                }
            } catch {
                print("❌ KidViewModel: Falha no banco compartilhado: \(error)")
                print("KidViewModel: Tentando banco privado...")
                
                // Se falhar no compartilhado, tenta o privado
                do {
                    let privateDB = container.privateCloudDatabase
                    let record = try await privateDB.record(for: kidID)
                    print("✅ KidViewModel: Kid encontrado no banco privado")
                    
                    DispatchQueue.main.async { [weak self] in
                        if let kid = Kid(record: record) {
                            self?.kid = kid
                            // Mesmo com kid no banco privado, tenta atividades no compartilhado para crianças
                            self?.loadActivitiesFromSharedDB(for: kid)
                        } else {
                            self?.isLoading = false
                            self?.handleError("Failed to convert private record to Kid")
                        }
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        print("❌ KidViewModel: Falha em ambos os bancos: \(error)")
                        self?.isLoading = false
                        self?.handleError("Failed to load kid from both databases: \(error.localizedDescription)")
                    }
                }
            }
        }
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
   
    // ✅ NOVO: Método público para carregar atividades (chamado pelo onReceive)
        func loadActivities() {
            guard let kid = kid else {
                print("❌ loadActivities: Kid ainda não está carregado")
                return
            }
            
            print("🔄 loadActivities: Iniciando carregamento das atividades para \(kid.name)")
            
            isLoadingActivities = true

            
            if UserManager.shared.isChild {
                loadActivitiesFromSharedDB(for: kid)
            } else if let currentKidID = currentKidID {
                loadActivities(for: kid, using: currentKidID.zoneID)
            } else {
                print("❌ loadActivities: currentKidID é nil")
                handleError("ID do filho não disponível")
            }
        }
    
    
    private func loadActivities(for kid: Kid, using zoneID: CKRecordZone.ID) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            print("KidViewModel: ID do filho não encontrado")
            isLoading = false
            return
        }
        
        print("🔍 KidViewModel: Carregando atividades")
        print("🔍 KidViewModel: kidID: \(kidID)")
        print("🔍 KidViewModel: zoneID: \(zoneID)")
        print("🔍 KidViewModel: Zone Owner: \(zoneID.ownerName)")
        
        feedbackMessage = "Carregando atividades..."
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        // CORREÇÃO: Determinar qual banco usar baseado no owner da zona E no role do usuário
        let isSharedZone = zoneID.ownerName != CKCurrentUserDefaultName
        let isChildUser = UserManager.shared.isChild
        
        print("KidViewModel: Para atividades - isSharedZone: \(isSharedZone), isChildUser: \(isChildUser)")
        
        // Para crianças, SEMPRE usar banco compartilhado se a zona for compartilhada
        let database = (isSharedZone || isChildUser) ?
                       container.sharedCloudDatabase :
                       container.privateCloudDatabase
        
        print("KidViewModel: Usando \((isSharedZone || isChildUser) ? "banco compartilhado" : "banco privado") para atividades")
        
        Task {
            do {
                // Buscar atividades diretamente na zona especificada
                let predicate = NSPredicate(format: "kidID == %@", kidID)
                let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: predicate)
                
                let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)
                print("KidViewModel: Encontrados \(results.count) registros de atividades")
                
                var allActivities: [ActivitiesRegister] = []
                
                for (id, result) in results {
                    switch result {
                    case .success(let record):
                        if let activity = ActivitiesRegister(record: record) {
                            allActivities.append(activity)
                            print("  ✅ Atividade carregada: \(activity.activity?.name ?? "Sem nome")")
                        }
                    case .failure(let error):
                        print("  ❌ Erro ao processar atividade: \(error)")
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.processLoadedActivities(allActivities, kidID: kidID)
                }
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingActivities = false
                    self?.handleError("Failed to load activities: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadActivitiesFromSharedDB(for kid: Kid) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            print("KidViewModel: ID do filho não encontrado")
            isLoading = false
            return
        }
        
        print("🔍 KidViewModel: Carregando atividades do banco compartilhado")
        print("🔍 KidViewModel: kidID procurado: \(kidID)")
        
        feedbackMessage = "Carregando atividades..."
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let sharedDB = container.sharedCloudDatabase
        
        Task {
            do {
                let zones = try await sharedDB.allRecordZones()
                print("KidViewModel: Zonas no banco compartilhado: \(zones.map { $0.zoneID.zoneName })")
                
                var allActivities: [ActivitiesRegister] = []
                
                for zone in zones {
                    print("\n🔍 KidViewModel: === TESTANDO ZONA: \(zone.zoneID.zoneName) ===")
                    
                    do {
                        let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
                        let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                        print("KidViewModel: Encontrados \(results.count) registros ScheduledActivity na zona \(zone.zoneID.zoneName)")
                        
                        for (id, result) in results {
                            switch result {
                            case .success(let record):
                                print("KidViewModel: 📋 Record: \(id.recordName)")
                                
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
                                        print("  - ✅ Atividade convertida com sucesso!")
                                        allActivities.append(activity)
                                    } else {
                                        print("  - ❌ Falha na conversão da atividade!")
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
                
                print("\n🔍 KidViewModel: === RESULTADO FINAL ===")
                print("KidViewModel: Total de atividades encontradas: \(allActivities.count)")
                
                DispatchQueue.main.async { [weak self] in
                    self?.processLoadedActivities(allActivities, kidID: kidID)
                }
            } catch {
                print("❌ KidViewModel: Erro geral ao carregar atividades: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingActivities = false
                    self?.handleError("Failed to load activities from shared database: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // CORREÇÃO CRÍTICA: Esta função estava limitando as atividades
    private func processLoadedActivities(_ allActivities: [ActivitiesRegister], kidID: String) {
        isLoadingActivities = false

        if allActivities.isEmpty {
            feedbackMessage = "❌ Nenhuma atividade encontrada para este filho"
            activities = []
            return
        }
        
        // ✅ CORREÇÃO: Salvar TODAS as atividades, não apenas as de hoje
        activities = allActivities.sorted { $0.date < $1.date }
        
        // Debug: Print all activities with their dates
        print("🔍 DEBUG: === TODAS AS ATIVIDADES CARREGADAS ===")
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for (index, activity) in activities.enumerated() {
            let isToday = Calendar.current.isDate(activity.date, inSameDayAs: Date())
            print("  \(index + 1). \(activity.activity?.name ?? "Unknown"): \(formatter.string(from: activity.date)) (Today: \(isToday))")
        }
        
        // Contar apenas as de hoje para feedback, mas não filtrar
        let todayActivities = activities.filter { activity in
            Calendar.current.isDate(activity.date, inSameDayAs: Date())
        }
        
        print("🔍 DEBUG: Current date: \(formatter.string(from: Date()))")
        print("🔍 DEBUG: Today's start: \(formatter.string(from: Calendar.current.startOfDay(for: Date())))")
        
        feedbackMessage = todayActivities.isEmpty
        ? "Nenhuma atividade para hoje (mas \(activities.count) atividades carregadas no total)"
        : "✅ Encontradas \(todayActivities.count) atividades para hoje (\(activities.count) no total)"
        
        print("📊 Total de atividades carregadas: \(activities.count)")
        print("📊 Atividades de hoje: \(todayActivities.count)")
        print("📊 Atividades não iniciadas hoje: \(notCompletedRegister().count)")
        print("📊 Atividades concluídas hoje: \(completedRegister().count)")
    }
    
    func refreshActivities() {
        if let kid = kid {
            isLoadingActivities = true

            if UserManager.shared.isChild {
                loadActivitiesFromSharedDB(for: kid)
            } else if let currentKidID = currentKidID {
                loadActivities(for: kid, using: currentKidID.zoneID)
            }
        } else {
            print("Couldn't refresh activities: no kid selected")
        }
    }
}

// MARK: - Activity Status Management
    extension KidViewModel {

        func toggleActivityCompletion(_ activity: ActivitiesRegister) {
                guard let activityID = activity.id else {
                    self.handleError("ID da atividade inválido")
                    return
                }
                
                guard let kidID = currentKidID else {
                    self.handleError("ID do filho não disponível")
                    return
                }
                
                let newStatus: RegisterStatus = activity.registerStatus == .completed ? .notCompleted : .completed
                let coinsToAdd = activity.activity?.rewardPoints ?? 0
                
                // Update locally first
                if let index = activities.firstIndex(where: { $0.id == activityID }) {
                    activities[index].registerStatus = newStatus
                }
                
                isLoading = true
                feedbackMessage = "Atualizando status da atividade..."
                
                Task {
                    do {
                        // Atualiza a atividade no CloudKit
                        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
                        let isSharedZone = kidID.zoneID.ownerName != CKCurrentUserDefaultName
                        let isChildUser = UserManager.shared.isChild
                        let database = (isSharedZone || isChildUser) ?
                                       container.sharedCloudDatabase :
                                       container.privateCloudDatabase
                        
                        let activityRecord = try await database.record(for: activityID)
                        activityRecord["status"] = newStatus.rawValue
                        let updatedActivityRecord = try await database.save(activityRecord)
                        
                        // Atualiza moedas através do CoinManager
                        if newStatus == .completed {
                            try await CoinManager.shared.addCoins(coinsToAdd, reason: "Atividade concluída: \(activity.activity?.name ?? "")")
                        } else {
                            try await CoinManager.shared.removeCoins(coinsToAdd, reason: "Atividade desfeita: \(activity.activity?.name ?? "")")
                        }
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.isLoading = false
                            self?.feedbackMessage = newStatus == .completed
                                ? "✅ Atividade concluída! +\(coinsToAdd) moedas"
                                : "↩️ Atividade desfeita! -\(coinsToAdd) moedas"
                            
                            if let updatedActivity = ActivitiesRegister(record: updatedActivityRecord),
                               let index = self?.activities.firstIndex(where: { $0.id == activityID }) {
                                self?.activities[index] = updatedActivity
                            }
                        
                        }
                        
                    } catch {
                        DispatchQueue.main.async { [weak self] in
                            self?.isLoading = false
                            
                            // Revert local change
                            if let index = self?.activities.firstIndex(where: { $0.id == activityID }) {
                                self?.activities[index].registerStatus = activity.registerStatus
                            }
                            
                            self?.handleError("Falha ao atualizar atividade: \(error.localizedDescription)")
                        }
                    }
                }
            }
        
        func isRegisterCompleted(_ register: ActivitiesRegister) -> Bool {
            // Aqui você verifica se o register está com status .completed
            return register.registerStatus == .completed
        }

        
        // MÉTODO AUXILIAR: Para debug das atividades
        func debugActivity(_ activity: ActivitiesRegister) {
            print("=== DEBUG ACTIVITY ===")
            print("Activity ID: \(activity.id?.recordName ?? "NIL")")
            print("Activity Name: \(activity.activity?.name ?? "Unknown")")
            print("Kid ID: \(activity.kidID)")
            print("Kid Reference: \(activity.kidReference?.recordID.recordName ?? "nil")")
            print("Activity ID Int: \(activity.activityID)")
            print("Status: \(activity.registerStatus)")
            print("Date: \(activity.date)")
            print("========================")
        }
        
        // MÉTODO AUXILIAR: Para debug de todas as atividades
        func debugAllActivities() {
            print("=== DEBUG ALL ACTIVITIES ===")
            print("Total de atividades: \(activities.count)")
            print("Atividades com ID nil: \(activities.filter { $0.id == nil }.count)")
            print("Atividades de hoje: \(registerForToday().count)")
            
            for (index, activity) in activities.enumerated() {
                print("\nAtividade \(index + 1):")
                print("  - ID: \(activity.id?.recordName ?? "NIL")")
                print("  - Nome: \(activity.activity?.name ?? "Unknown")")
                print("  - Status: \(activity.registerStatus)")
                print("  - Data: \(activity.date)")
                print("  - É de hoje? \(Calendar.current.isDate(activity.date, inSameDayAs: Date()))")
            }
            print("============================")
        }
            
}

// MARK: - Data Filtering (CORRIGIDO)
extension KidViewModel {
    
    func registerForToday() -> [ActivitiesRegister] {
        guard let kidID = kid?.id?.recordName else {
            print("🔍 DEBUG: registerForToday - kidID é nil")
            return []
        }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        print("🔍 DEBUG: registerForToday chamado")
        print("🔍 DEBUG: kidID procurado: \(kidID)")
        print("🔍 DEBUG: Total de atividades: \(activities.count)")
        print("🔍 DEBUG: Início do dia: \(startOfToday)")
        print("🔍 DEBUG: Fim do dia: \(endOfToday)")
        
        let result = activities.filter { activity in
            let belongsToKid = activity.kidID == kidID ||
                              activity.kidReference?.recordID.recordName == kidID
            
            // ✅ CORREÇÃO: Usar range de datas em vez de isDate(inSameDayAs:)
            let isToday = activity.date >= startOfToday && activity.date < endOfToday
            
            print("🔍 DEBUG: Atividade '\(activity.activity?.name ?? "Unknown")':")
            print("  - activity.kidID: \(activity.kidID)")
            print("  - kidReference?.recordID.recordName: \(activity.kidReference?.recordID.recordName ?? "nil")")
            print("  - belongsToKid: \(belongsToKid)")
            print("  - activity.date: \(activity.date)")
            print("  - isToday: \(isToday)")
            print("  - incluir?: \(belongsToKid && isToday)")
            
            return belongsToKid && isToday
        }
        .sorted { $0.date < $1.date }
        
        print("🔍 DEBUG: registerForToday retornando \(result.count) atividades")
        return result
    }
    
    // ✅ MÉTODO ALTERNATIVO: Para debug - retorna todas as atividades do kid
    func allActivitiesForKid() -> [ActivitiesRegister] {
        guard let kidID = kid?.id?.recordName else {
            print("🔍 DEBUG: allActivitiesForKid - kidID é nil")
            return []
        }
        
        let result = activities.filter { activity in
            let belongsToKid = activity.kidID == kidID ||
                              activity.kidReference?.recordID.recordName == kidID
            return belongsToKid
        }
        .sorted { $0.date < $1.date }
        
        print("🔍 DEBUG: allActivitiesForKid retornando \(result.count) atividades")
        return result
    }
    
    func notCompletedRegister() -> [ActivitiesRegister] {
        // ✅ TEMPORÁRIO: Use todas as atividades para debug
        let todayActivities = registerForToday()
        let result = todayActivities.filter { $0.registerStatus == .notCompleted }
        
        print("🔍 DEBUG: notCompletedRegister - atividades de hoje: \(todayActivities.count)")
        print("🔍 DEBUG: notCompletedRegister retornando \(result.count) atividades não concluídas")
        
        return result
    }
    
    func completedRegister() -> [ActivitiesRegister] {
        let todayActivities = registerForToday()
        let result = todayActivities.filter { $0.registerStatus == .completed }
        
        print("🔍 DEBUG: completedRegister - atividades de hoje: \(todayActivities.count)")
        print("🔍 DEBUG: completedRegister retornando \(result.count) atividades concluídas")
        
        return result
    }
    
    // ✅ MÉTODO ADICIONAL: Para debug - mostra todas as datas das atividades
    func debugActivityDates() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        print("🔍 DEBUG: === TODAS AS DATAS DAS ATIVIDADES ===")
        print("🔍 DEBUG: Data atual: \(formatter.string(from: Date()))")
        
        for (index, activity) in activities.enumerated() {
            print("🔍 DEBUG: \(index + 1). \(activity.activity?.name ?? "Unknown"): \(formatter.string(from: activity.date))")
        }
        print("🔍 DEBUG: =======================================")
    }
}

// MARK: - Invitation Management
extension KidViewModel {
    
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
