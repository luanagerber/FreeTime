//
//  KidReceiverView.swift
//  FreeTime
//
//  Created by Maria Tereza Martins Pérez on 21/05/25.
//

import SwiftUI
import CloudKit

struct KidReceiverView: View {
    @AppStorage("userRole") private var userRole: String?
    
    @State private var isLoading = false
    @State private var feedbackMessage = ""
    @State private var kid: Kid?
    @State private var activities: [ActivitiesRegister] = []
    
    private var cloudService: CloudService = .shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                    
                    if let kid = kid {
                        kidProfileView(kid)
                        
                        activitiesListView()
                    } else {
                        waitingForInviteView()
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
                }
                .padding()
                .onAppear {
                    checkForSharedKid()
                }
            }
            .navigationTitle("Modo Filho(a)")
            .refreshable {
                refresh()
            }
        }
    }
    
    @ViewBuilder
    private func kidProfileView(_ kid: Kid) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(kid.name.prefix(1)))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                )
            
            Text(kid.name)
                .font(.title2)
                .fontWeight(.bold)
                
            Text("Suas atividades")
                .font(.headline)
                .padding(.top, 10)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func activitiesListView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if activities.isEmpty {
                Text("Nenhuma atividade encontrada")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(activities) { activity in
                    activityCardView(activity)
                }
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private func activityCardView(_ activity: ActivitiesRegister) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Tenta encontrar a atividade pelo ID
                if let activityInfo = Activity.catalog.first(where: { $0.id == activity.activityID }) {
                    Text(activityInfo.name)
                        .font(.headline)
                } else {
                    Text("Atividade")
                        .font(.headline)
                }
                
                Spacer()
                
                statusBadge(for: activity.registerStatus)
            }
            
            Text(activity.date.timeRange(duration: activity.duration))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if activity.registerStatus != .completed {
                HStack {
                    Spacer()
                    Button(action: {
                        updateActivityStatus(activity)
                    }) {
                        Text(activity.registerStatus == .notStarted ? "Iniciar" : "Concluir")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func statusBadge(for status: RegisterStatus) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status == .notStarted ? Color.yellow :
                      status == .inProgress ? Color.blue : Color.green)
                .frame(width: 10, height: 10)
            
            Text(status == .notStarted ? "Pendente" :
                 status == .inProgress ? "Em andamento" : "Concluído")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func waitingForInviteView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Aguardando Convite")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Você ainda não aceitou um convite de um pai ou responsável. Quando receber um convite, abra-o em seu dispositivo para acessar suas atividades.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Cloud methods
    
    private func refresh() {
        checkForSharedKid()
    }
    
    private func checkForSharedKid() {
        guard let rootRecordID = cloudService.getRootRecordID() else {
            feedbackMessage = "Nenhum convite aceito ainda"
            return
        }
        
        isLoading = true
        feedbackMessage = "Verificando convite aceito..."
        
        // Não tentar criar zonas - usar diretamente o banco compartilhado e o ID do registro
        fetchKidInfo(rootRecordID: rootRecordID)
    }

    private func fetchKidInfo(rootRecordID: CKRecord.ID) {
        // Obter o container e o banco compartilhado diretamente
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let sharedDB = container.sharedCloudDatabase
        
        Task {
            do {
                // Acessar o registro diretamente pelo ID no banco compartilhado
                let record = try await sharedDB.record(for: rootRecordID)
                print("✅ Registro compartilhado encontrado: \(record.recordID.recordName)")
                
                // Criar um KidRecord a partir do registro
                if let kid = Kid(record: record) {
                    DispatchQueue.main.async {
                        self.kid = kid
                        self.feedbackMessage = "✅ Conectado como \(kid.name)"
                        // Agora carregamos as atividades usando a zoneID original do registro
                        self.loadActivities(for: kid, using: record.recordID.zoneID)
                    }
                } else {
                    print("❌ Falha ao converter o registro para KidRecord")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.feedbackMessage = "❌ Erro ao carregar informações do registro compartilhado"
                    }
                }
            } catch {
                print("❌ Erro ao acessar registro compartilhado: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.feedbackMessage = "❌ Erro ao carregar convite: \(error)"
                }
            }
        }
    }

    private func loadActivities(for kid: Kid, using zoneID: CKRecordZone.ID) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            print("FILHO: ID do filho não encontrado")
            isLoading = false
            return
        }
        
        print("🔍 FILHO: Iniciando busca de atividades")
        print("🔍 FILHO: kidID procurado: \(kidID)")
        print("🔍 FILHO: zoneID: \(zoneID)")
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        
        // Obter o container e o banco compartilhado diretamente
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let sharedDB = container.sharedCloudDatabase
        
        Task {
            do {
                let zones = try await sharedDB.allRecordZones()
                print("FILHO: Zonas disponíveis no banco compartilhado: \(zones.map { $0.zoneID.zoneName })")
                
                var allActivities: [ActivitiesRegister] = []
                
                // BUSCA DETALHADA: Vamos testar TODAS as abordagens possíveis
                for zone in zones {
                    print("\n🔍 FILHO: === TESTANDO ZONA: \(zone.zoneID.zoneName) ===")
                    
                    // TESTE 1: Busca geral por ScheduledActivity
                    print("🔍 FILHO: Teste 1 - Busca geral por ScheduledActivity")
                    do {
                        let generalQuery = CKQuery(recordType: RecordType.activity.rawValue, predicate: NSPredicate(value: true))
                        let (generalResults, _) = try await sharedDB.records(matching: generalQuery, inZoneWith: zone.zoneID)
                        print("FILHO: Teste 1 - Encontrados \(generalResults.count) registros ScheduledActivity")
                        
                        for (id, result) in generalResults {
                            switch result {
                            case .success(let record):
                                print("FILHO: 📋 Record: \(id.recordName)")
                                print("  - Tipo: \(record.recordType)")
                                print("  - Campos: \(record.allKeys())")
                                
                                let recordKidID = record["kidID"] as? String
                                let recordKidRef = record["kidReference"] as? CKRecord.Reference
                                
                                print("  - kidID: \(recordKidID ?? "nil")")
                                print("  - kidReference: \(recordKidRef?.recordID.recordName ?? "nil")")
                                print("  - Match kidID? \(recordKidID == kidID)")
                                print("  - Match kidRef? \(recordKidRef?.recordID.recordName == kidID)")
                                
                                // Tentar converter para ActivitiesRegister
                                if let activity = ActivitiesRegister(record: record) {
                                    print("  - ✅ Conversão bem-sucedida!")
                                    allActivities.append(activity)
                                } else {
                                    print("  - ❌ Falha na conversão!")
                                }
                                
                            case .failure(let error):
                                print("FILHO: ❌ Erro ao processar registro: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("FILHO: ❌ Erro no Teste 1: \(error.localizedDescription)")
                    }
                    
                    // TESTE 2: Verificar TODOS os tipos de registro existentes
                    print("\n🔍 FILHO: Teste 2 - Verificar todos os tipos de registro")
                    for recordType in ["Kid", "ScheduledActivity", "Activity"] {
                        do {
                            let typeQuery = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                            let (typeResults, _) = try await sharedDB.records(matching: typeQuery, inZoneWith: zone.zoneID)
                            print("FILHO: Tipo '\(recordType)': \(typeResults.count) registros")
                            
                            if recordType == "ScheduledActivity" || recordType == "Activity" {
                                for (id, result) in typeResults {
                                    switch result {
                                    case .success(let record):
                                        print("FILHO: 📋 \(recordType): \(id.recordName)")
                                        print("  - kidID: \(record["kidID"] ?? "nil")")
                                        print("  - activityID: \(record["activityID"] ?? "nil")")
                                    case .failure(let error):
                                        print("FILHO: ❌ Erro: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } catch {
                            print("FILHO: ❌ Erro ao buscar '\(recordType)': \(error.localizedDescription)")
                        }
                    }
                }
                
                print("\n🔍 FILHO: === CONCLUSÃO ===")
                if allActivities.isEmpty {
                    print("FILHO: ❌ PROBLEMA CONFIRMADO: Nenhuma atividade existe no banco compartilhado!")
                    print("FILHO: ❌ As atividades não estão sendo compartilhadas pelo pai!")
                } else {
                    print("FILHO: ✅ Encontradas \(allActivities.count) atividades")
                }
                
                // Processar resultado
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if allActivities.isEmpty {
                        self.feedbackMessage = "❌ Nenhuma atividade no banco compartilhado"
                        self.activities = []
                        return
                    }
                    
                    // Filtra atividades para hoje
                    let calendar = Calendar.current
                    self.activities = allActivities.filter { activity in
                        calendar.isDateInToday(activity.date)
                    }
                    
                    self.feedbackMessage = self.activities.isEmpty
                        ? "Nenhuma atividade para hoje"
                        : "✅ Encontradas \(self.activities.count) atividades para hoje"
                }
            } catch {
                print("FILHO: ❌ Erro geral: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.feedbackMessage = "❌ Erro ao carregar atividades: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateActivityStatus(_ activity: ActivitiesRegister) {
        guard let activityID = activity.id else {
            feedbackMessage = "ID da atividade não encontrado"
            return
        }

        var updatedActivity = activity
        
        // Atualiza o status da atividade
        if updatedActivity.registerStatus == .notStarted {
            updatedActivity.registerStatus = .inProgress
        } else if updatedActivity.registerStatus == .inProgress {
            updatedActivity.registerStatus = .completed
        }
        
        isLoading = true
        feedbackMessage = "Atualizando status da atividade..."
        
        // Obter o container e o banco compartilhado diretamente
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let sharedDB = container.sharedCloudDatabase
        
        // Atualizar diretamente no banco compartilhado
        Task {
            do {
                // Buscar o registro atual
                let record = try await sharedDB.record(for: activityID)
                
                // Atualizar o status
                record["status"] = updatedActivity.registerStatus.rawValue
                
                // Salvar as alterações
                let updatedRecord = try await sharedDB.save(record)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.feedbackMessage = "✅ Status atualizado com sucesso"
                    
                    // Atualizar a atividade na lista
                    if let updatedActivity = ActivitiesRegister(record: updatedRecord),
                       let index = self.activities.firstIndex(where: { $0.id == activityID }) {
                        self.activities[index] = updatedActivity
                    }
                }
            } catch {
                print("FILHO: Erro ao atualizar status: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.feedbackMessage = "❌ Erro ao atualizar status: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    KidReceiverView()
}
