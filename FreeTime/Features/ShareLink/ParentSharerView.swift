
import SwiftUI
import CloudKit

struct ParentSharerView: View {
    @AppStorage("userRole") private var userRole: String?
    
    @State private var childName = ""
    @State private var kids: [Kid] = []
    @State private var selectedKid: Kid?
    @State private var isLoading = false
    @State private var feedbackMessage = ""
    @State private var sharingSheet: Bool = false
    @State private var shareView: AnyView?
    @State private var zoneReady = false
    
    // Estados para adicionar atividades
    @State private var showActivitySelector = false
    @State private var selectedActivity: Activity?
    @State private var scheduledDate = Date()
    @State private var duration: TimeInterval = 3600 // 1 hora padrão
    
    private var cloudService: CloudService = .shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Gerenciador de Atividades")
                        .font(.title)
                        .padding()
                    
                    // Botão de refresh
                    Button(action: refresh) {
                        Label("Atualizar dados", systemImage: "arrow.clockwise")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    
                    // Seção para adicionar criança
                    VStack(alignment: .leading) {
                        Text("Adicionar nova criança")
                            .font(.headline)
                        
                        TextField("Nome da criança", text: $childName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 8)
                        
                        Button("Adicionar Criança") {
                            addChild()
                        }
                        .disabled(childName.isEmpty || isLoading || !zoneReady)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Lista de crianças
                    if !kids.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Suas Crianças")
                                .font(.headline)
                            
                            List(kids, id: \.id) { kid in
                                HStack {
                                    Text(kid.name)
                                    Spacer()
                                    Button("Atribuir Atividade") {
                                        selectedKid = kid
                                        showActivitySelector = true
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Compartilhar") {
                                        selectedKid = kid
                                        shareKid(kid)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    } else if !isLoading && zoneReady {
                        Text("Nenhuma criança cadastrada. Adicione uma criança usando o formulário acima.")
                            .foregroundColor(.secondary)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                    
                    // Indicador de loading
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    // Mensagem de feedback
                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Botão para sair do papel
                    Button("Trocar papel") {
                        userRole = nil
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    setupCloudKit()
                }
                .sheet(isPresented: $sharingSheet) {
                    if let shareView = shareView {
                        shareView
                    } else {
                        Text("Preparando compartilhamento...")
                    }
                }
                .sheet(isPresented: $showActivitySelector) {
                    activitySelectorView
                }
            }
            .navigationTitle("Modo Pai/Mãe")
            .refreshable {
                refresh()
            }
        }
    }
    
    // View para selecionar atividade
    private var activitySelectorView: some View {
        NavigationView {
            VStack {
                // Lista de atividades disponíveis
                List(Activity.catalog, id: \.id) { activity in
                    Button(action: {
                        selectedActivity = activity
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                Text(activity.description)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selectedActivity?.id == activity.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Seletor de data e duração
                DatePicker("Data e hora", selection: $scheduledDate)
                    .padding()
                
                Picker("Duração", selection: $duration) {
                    Text("30 minutos").tag(TimeInterval(1800))
                    Text("1 hora").tag(TimeInterval(3600))
                    Text("1 hora e 30 minutos").tag(TimeInterval(5400))
                    Text("2 horas").tag(TimeInterval(7200))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Botão para agendar atividade
                Button("Agendar Atividade") {
                    scheduleActivity()
                }
                .disabled(selectedActivity == nil || selectedKid == nil)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            .navigationTitle("Selecionar Atividade")
            .navigationBarItems(trailing: Button("Cancelar") {
                showActivitySelector = false
            })
        }
    }
    
    // MARK: - Métodos de Cloud
    private func refresh() {
        isLoading = true
        feedbackMessage = "Atualizando dados..."
        
        if !zoneReady {
            setupCloudKit()
            return
        }
        
        // Primeiro, carregar as crianças
        cloudService.fetchAllKids { result in
            switch result {
            case .success(let fetchedKids):
                self.kids = fetchedKids
                
                // Se temos crianças e alguma foi selecionada, verificar por atividades atualizadas
                if let selectedKid = self.selectedKid, !fetchedKids.isEmpty {
                    // Buscar também no banco compartilhado para pegar atualizações do filho
                    guard let kidID = selectedKid.id?.recordName else {
                        self.isLoading = false
                        self.feedbackMessage = "✅ Dados atualizados"
                        return
                    }
                    
                    // Buscar atividades tanto no banco privado quanto no compartilhado
                    self.loadSharedActivities(for: kidID)
                } else {
                    self.isLoading = false
                    let message = fetchedKids.isEmpty
                        ? "Nenhuma criança encontrada no CloudKit"
                        : "✅ Carregadas \(fetchedKids.count) crianças"
                    self.feedbackMessage = message
                }
                
            case .failure(let error):
                self.isLoading = false
                let errorMessage = "❌ Erro ao carregar crianças: \(error)"
                self.feedbackMessage = errorMessage
                print(errorMessage)
            }
        }
    }

    // Adicionar este método para buscar atividades compartilhadas
    private func loadSharedActivities(for kidID: String) {
        // Verificar se há atividades compartilhadas pelo filho que foram modificadas
        cloudService.fetchSharedActivities(forKid: kidID) { (result: Result<[ActivitiesRegister], CloudError>) in
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sharedActivities):
                    // Se encontrar atividades compartilhadas modificadas, atualizar o banco de dados local
                    if !sharedActivities.isEmpty {
                        self.syncActivitiesWithPrivateDB(sharedActivities, kidID: kidID)
                    } else {
                        self.feedbackMessage = "✅ Dados atualizados"
                    }
                case .failure:
                    // Continue mesmo se não encontrar atividades compartilhadas
                    self.feedbackMessage = "✅ Dados atualizados"
                }
            }
        }
    }

    // Sincronizar atividades do banco compartilhado com o banco privado
    private func syncActivitiesWithPrivateDB(_ sharedActivities: [ActivitiesRegister], kidID: String) {
        // Buscar atividades privadas primeiro
        cloudService.fetchAllActivities(forKid: kidID) { (result: Result<[ActivitiesRegister], CloudError>) in
            
            switch result {
            case .success(let privateActivities):
                // Para cada atividade compartilhada, verificar se precisamos atualizar a versão privada
                var activitiesToUpdate: [ActivitiesRegister] = []
                
                for sharedActivity in sharedActivities {
                    // Buscar atividade correspondente no banco privado
                    if let privateVersion = privateActivities.first(where: { $0.activityID == sharedActivity.activityID }) {
                        // Se o status da atividade compartilhada é diferente, precisamos atualizar
                        if privateVersion.status != sharedActivity.registerStatus {
                            // Criar uma versão atualizada para o banco privado
                            var updatedActivity = privateVersion
                            updatedActivity.status = sharedActivity.registerStatus
                            activitiesToUpdate.append(updatedActivity)
                        }
                    }
                }
                
                // Atualizar atividades que precisam de sincronização
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

    // Atualizar atividades no banco privado
    private func updatePrivateActivities(_ activities: [ActivitiesRegister]) {
        let dispatchGroup = DispatchGroup()
        var updatedCount = 0
        
        for activity in activities {
            dispatchGroup.enter()
            
            cloudService.updateActivity(activity, isShared: false) { result in
                switch result {
                case .success:
                    updatedCount += 1
                case .failure:
                    // Continue mesmo com falhas
                    break
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.feedbackMessage = "✅ Dados atualizados - \(updatedCount) atividades sincronizadas"
        }
    }
    
    private func setupCloudKit() {
        feedbackMessage = "Configurando CloudKit..."
        print("Configurando CloudKit...")
        isLoading = true
        
        Task {
            do {
                try await cloudService.createZoneIfNeeded()
                print("✅ Zona Kids criada ou verificada")
                
                DispatchQueue.main.async {
                    self.zoneReady = true
                    self.feedbackMessage = "✅ CloudKit configurado com sucesso"
                    self.loadKids()
                }
            } catch {
                print("❌ ERRO CRÍTICO: Falha ao configurar CloudKit: \(error.localizedDescription)")
                
                // Se o erro for Zone Not Found, tentar criar novamente após um breve atraso
                if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                    print("📋 Tentando criar zona novamente em 2 segundos...")
                    
                    // Esperar 2 segundos e tentar novamente
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    
                    do {
                        try await self.cloudService.createZoneIfNeeded()
                        print("✅ Zona Kids criada com sucesso na segunda tentativa")
                        
                        DispatchQueue.main.async {
                            self.zoneReady = true
                            self.feedbackMessage = "✅ CloudKit configurado com sucesso (segunda tentativa)"
                            self.loadKids()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.feedbackMessage = "❌ Erro crítico ao configurar CloudKit. Por favor, reinicie o aplicativo."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.feedbackMessage = "❌ Erro: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func addChild() {
        guard !childName.isEmpty else { return }
        
        isLoading = true
        feedbackMessage = "Adicionando criança ao CloudKit..."
        
        let kid = Kid(name: childName) // Using updated Kid initializer
        print("Tentando adicionar criança com nome: \(kid.name)")
        
        // Checa se o record está sendo criado corretamente
        if kid.record == nil {
            DispatchQueue.main.async {
                isLoading = false
                feedbackMessage = "❌ Erro: Falha ao criar registro da criança (registro é nulo)"
                print("Falha ao criar registro da criança - registro é nulo")
            }
            return
        }
        
        cloudService.saveKid(kid) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let newKid):
                    print("✅ Adicionado com sucesso \(newKid.name) ao CloudKit")
                    feedbackMessage = "✅ Adicionado com sucesso \(newKid.name) ao CloudKit"
                    childName = ""
                    loadKids()
                case .failure(let error):
                    print("❌ Erro ao adicionar criança: \(error)")
                    feedbackMessage = "❌ Erro ao adicionar criança: \(error)"
                }
            }
        }
    }
    
    private func scheduleActivity() {
        guard let kid = selectedKid, let activity = selectedActivity else { return }
        
        isLoading = true
        feedbackMessage = "Agendando atividade para \(kid.name)..."
        
        // Obter o recordName diretamente
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "❌ Erro: ID da criança não encontrado"
            isLoading = false
            return
        }
        
        // Usar o recordName diretamente como string
        let kidName = kid.id
        
        print("DETALHADO: Criando atividade para \(kid.name) com ID \(kidName)")
        print("DETALHADO: ActivityID: \(activity.id)")
        print("DETALHADO: Data: \(scheduledDate)")
        print("DETALHADO: Adicionando referência ao Kid com ID: \(kidID)")

        // Criar registro de atividade usando o novo inicializador
        var activityRegister = ActivitiesRegister(
            kidID: kidID,
            activityID: activity.id,
            date: scheduledDate,
            duration: duration,
            registerStatus: .notStarted
        )
        
        // Converter para ActivitiesRegister usando o recordName como kidID e passando a referência ao Kid
        let activity = ActivitiesRegister(
            register: register,
            kidID: kidName,
            kidID: kidID  // Passar o CKRecord.ID para criar a referência
        )
        
        // Verificar se a referência foi configurada
        if activity.kidReference != nil {
            print("DETALHADO: KidReference configurada corretamente")
        } else {
            print("DETALHADO: ERRO - KidReference não configurada!")
            // Tentar configurar manualmente se não estiver configurada
            if let record = activityRecord.record {
                record["kidReference"] = CKRecord.Reference(recordID: kidID, action: .deleteSelf)
                print("DETALHADO: KidReference configurada manualmente")
            }
        }
        
        // Salvar a atividade e depois atualizar o compartilhamento
        cloudService.saveActivity(activity) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let savedActivity):
                    print("✅ Atividade criada com sucesso para \(kid.name), recordName: \(kidName)")
                    print("DETALHADO: Atividade salva com ID: \(savedActivity.id?.recordName ?? "unknown")")
                    
                    // Verificar se a criança já tem compartilhamento
                    if let shareReference = kid.shareReference {
                        print("DETALHADO: Criança já tem compartilhamento (ID: \(shareReference.recordID.recordName)), atualizando...")
                        
                        // Diagnóstico do compartilhamento existente
                        Task {
                            await self.diagnosticarCompartilhamento(kidID: kidID)
                        }
                        
                        // Recompartilhar para garantir que as novas atividades sejam incluídas
                        Task {
                            do {
                                try await self.cloudService.shareKid(kid) { result in
                                    switch result {
                                    case .success:
                                        print("DETALHADO: Compartilhamento atualizado após nova atividade")
                                        
                                        // Verificar se a atividade foi corretamente incluída no compartilhamento
                                        Task {
                                            await self.verificarAtividadeNoCompartilhamento(
                                                kidID: kidName,
                                                activityID: savedActivity.id?.recordName ?? ""
                                            )
                                        }
                                        
                                    case .failure(let error):
                                        print("DETALHADO: Erro no retorno do compartilhamento: \(error)")
                                    }
                                }
                            } catch {
                                print("DETALHADO: Erro ao atualizar compartilhamento: \(error)")
                            }
                        }
                    } else {
                        print("DETALHADO: Criança não tem compartilhamento ainda, criando...")
                        // Se não tiver compartilhamento, cria um novo
                        Task {
                            do {
                                try await self.cloudService.shareKid(kid) { result in
                                    switch result {
                                    case .success:
                                        print("DETALHADO: Compartilhamento criado após nova atividade")
                                        DispatchQueue.main.async {
                                            self.refresh() // Atualizar a lista de kids para obter o shareReference atualizado
                                        }
                                    case .failure(let error):
                                        print("DETALHADO: Erro ao criar compartilhamento: \(error)")
                                    }
                                }
                            } catch {
                                print("DETALHADO: Erro ao criar compartilhamento: \(error)")
                            }
                        }
                    }
                    
                    self.feedbackMessage = "✅ Atividade '\(activity.name)' agendada para \(kid.name)"
                    self.showActivitySelector = false
                    
                    // Executar diagnóstico completo
                    Task {
                        await self.cloudService.debugShareStatus(forKid: kid)
                        await self.cloudService.debugSharedDatabase()
                    }

                case .failure(let error):
                    print("❌ Erro ao agendar atividade: \(error)")
                    self.feedbackMessage = "❌ Erro ao agendar atividade: \(error)"
                }
            }
        }
    }

    private func diagnosticarCompartilhamento(kidID: CKRecord.ID) async {
        print("DIAGNÓSTICO: Verificando compartilhamento para Kid ID: \(kidID.recordName)")
        
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let privateDB = container.privateCloudDatabase
        
        do {
            // Buscar o registro original
            let kidRecord = try await privateDB.record(for: kidID)
            let shareReference = kidRecord.share
            
            if let shareReference = shareReference {
                print("DIAGNÓSTICO: Kid tem referência para share: \(shareReference.recordID.recordName)")
                
                // Buscar o CKShare
                let share = try await privateDB.record(for: shareReference.recordID) as? CKShare
                
                if let share = share {
                    print("DIAGNÓSTICO: Share encontrado com sucesso")
                    print("DIAGNÓSTICO: - Permissão pública: \(share.publicPermission.rawValue)")
                    print("DIAGNÓSTICO: - Participantes: \(share.participants.count)")
                    print("DIAGNÓSTICO: - URL: \(share.url?.absoluteString ?? "nil")")
                    
                    // Correção: proprietário é não-opcional e currentUserParticipant pode ser opcional
                    let owner = share.owner
                    if let currentUserParticipant = share.currentUserParticipant {
                        print("DIAGNÓSTICO: - Usuário atual é owner? \(owner.userIdentity == currentUserParticipant.userIdentity)")
                    } else {
                        print("DIAGNÓSTICO: - Usuário atual não é participante do compartilhamento")
                    }
                } else {
                    print("DIAGNÓSTICO: Share não encontrado, apesar da referência existir")
                }
            } else {
                print("DIAGNÓSTICO: Kid não tem referência para share")
            }
        } catch {
            print("DIAGNÓSTICO: Erro ao buscar registro ou share: \(error.localizedDescription)")
        }
    }
    
    private func verificarAtividadeNoCompartilhamento(kidID: String, activityID: String) async {
        print("VERIFICAÇÃO: Buscando atividade \(activityID) para Kid \(kidID) no banco compartilhado")
        
        guard let rootRecordID = cloudService.getRootRecordID() else {
            print("VERIFICAÇÃO: Nenhum rootRecordID encontrado")
            return
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let sharedDB = container.sharedCloudDatabase
        
        // Primeiro tentar buscar pelo ID exato
        if !activityID.isEmpty {
            do {
                let activityRecordID = CKRecord.ID(recordName: activityID, zoneID: rootRecordID.zoneID)
                let record = try await sharedDB.record(for: activityRecordID)
                print("VERIFICAÇÃO: Atividade encontrada diretamente pelo ID!")
                print("VERIFICAÇÃO: - Fields: \(record.allKeys().map { "\($0): \(String(describing: record[$0]))" }.joined(separator: ", "))")
                return
            } catch {
                print("VERIFICAÇÃO: Não foi possível encontrar a atividade pelo ID: \(error.localizedDescription)")
            }
        }
        
        // Se não encontrar pelo ID, tentar buscar por query
        let kidReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: kidID, zoneID: rootRecordID.zoneID), action: .none)
        
        let predicates = [
            NSPredicate(format: "kidID == %@", kidID),
            NSPredicate(format: "kidReference == %@", kidReference)
        ]
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: compoundPredicate)
        
        do {
            let (results, _) = try await sharedDB.records(matching: query)
            
            if results.isEmpty {
                print("VERIFICAÇÃO: Nenhuma atividade encontrada no banco compartilhado")
            } else {
                print("VERIFICAÇÃO: Encontradas \(results.count) atividades no banco compartilhado")
                
                for (index, result) in results.enumerated() {
                    switch result.1 {
                    case .success(let record):
                        print("VERIFICAÇÃO: Atividade \(index) - ID: \(record.recordID.recordName)")
                        print("VERIFICAÇÃO: - Fields: \(record.allKeys().map { "\($0): \(String(describing: record[$0]))" }.joined(separator: ", "))")
                    case .failure(let error):
                        print("VERIFICAÇÃO: Erro ao processar registro \(index): \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("VERIFICAÇÃO: Erro ao buscar atividades: \(error.localizedDescription)")
        }
    }
    
    private func loadKids() {
        isLoading = true
        feedbackMessage = "Carregando suas crianças do CloudKit..."
        print("Carregando crianças do CloudKit...")
        
        cloudService.fetchAllKids { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedKids):
                    kids = fetchedKids
                    let message = fetchedKids.isEmpty
                        ? "Nenhuma criança encontrada no CloudKit"
                        : "✅ Carregadas \(fetchedKids.count) crianças"
                    feedbackMessage = message
                    print(message)
                case .failure(let error):
                    let errorMessage = "❌ Erro ao carregar crianças: \(error)"
                    feedbackMessage = errorMessage
                    print(errorMessage)
                }
            }
        }
    }
    
    private func shareKid(_ kid: Kid) {
        isLoading = true
        feedbackMessage = "Gerando link de compartilhamento para \(kid.name)..."
        print("Gerando link de compartilhamento para \(kid.name)...")
        
        Task {
            do {
                try await cloudService.shareKid(kid) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let view):
                            shareView = AnyView(view)
                            feedbackMessage = "✅ Compartilhamento preparado para \(kid.name)"
                            print("✅ Compartilhamento preparado para \(kid.name)")
                            sharingSheet = true
                        case .failure(let error):
                            let errorMessage = "❌ Erro ao compartilhar criança: \(error)"
                            feedbackMessage = errorMessage
                            print(errorMessage)
                        }
                    }
                }
            } catch {
                let errorMessage = "❌ Erro: \(error.localizedDescription)"
                print(errorMessage)
                DispatchQueue.main.async {
                    isLoading = false
                    feedbackMessage = errorMessage
                }
            }
        }
    }
}

#Preview {
    ParentSharerView()
}
