
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
        if zoneReady {
            loadKids()
        } else {
            setupCloudKit()
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
                    zoneReady = true
                    feedbackMessage = "✅ CloudKit configurado com sucesso"
                    loadKids()
                }
            } catch {
                let errorMessage = "❌ Erro ao configurar CloudKit: \(error.localizedDescription)"
                print(errorMessage)
                DispatchQueue.main.async {
                    isLoading = false
                    feedbackMessage = errorMessage
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
        
        print("Agendando atividade para kid: \(kid.name), recordName: \(kidID)")
        
        // Criar registro de atividade usando o novo inicializador
        var activityRegister = ActivitiesRegister(
            kidID: kidID,
            activityID: activity.id,
            date: scheduledDate,
            duration: duration,
            registerStatus: .notStarted
        )
        
        // Se o kid tiver um ID, definir a referência
        if let kidRecordID = kid.id {
            activityRegister.kidReference = CKRecord.Reference(recordID: kidRecordID, action: .deleteSelf)
        }
        
        cloudService.saveActivity(activityRegister) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(_):
                    print("✅ Atividade criada com sucesso para \(kid.name), recordName: \(kidID)")
                    feedbackMessage = "✅ Atividade '\(activity.name)' agendada para \(kid.name)"
                    showActivitySelector = false
                case .failure(let error):
                    print("❌ Erro ao agendar atividade: \(error)")
                    feedbackMessage = "❌ Erro ao agendar atividade: \(error)"
                }
            }
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
