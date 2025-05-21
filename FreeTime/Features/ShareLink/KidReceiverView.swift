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
                if let kidRecord = KidRecord(record: record) {
                    DispatchQueue.main.async {
                        self.kid = kidRecord
                        self.feedbackMessage = "✅ Conectado como \(kidRecord.name)"
                        // Agora carregamos as atividades usando a zoneID original do registro
                        self.loadActivities(for: kidRecord, using: record.recordID.zoneID)
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
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        print("FILHO: Buscando atividades para kidID: \(kidID) na zona: \(zoneID.zoneName)")
        
        // IMPORTANTE: Verificar se temos o rootRecordID
        if let rootRecordID = cloudService.getRootRecordID() {
            print("FILHO: Root Record ID: \(rootRecordID.recordName)")
            print("FILHO: Root Zone: \(rootRecordID.zoneID.zoneName)")
        } else {
            print("FILHO: Root Record ID não encontrado!")
        }
        
        // Obter o container e o banco compartilhado diretamente
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        let sharedDB = container.sharedCloudDatabase
        
        // IMPORTANTE: Buscar atividades em todas as zonas disponíveis
        Task {
            do {
                let zones = try await sharedDB.allRecordZones()
                print("FILHO: Zonas disponíveis no banco compartilhado: \(zones.map { $0.zoneID.zoneName })")
                
                // Agora vamos tentar buscar atividades em todas as zonas
                print("FILHO: Iniciando busca abrangente de atividades em todas as zonas")
                
                var allActivities: [ActivitiesRegister] = []

                for zone in zones {
                    print("FILHO: Buscando na zona: \(zone.zoneID.zoneName)")
                    
                    // Buscar usando todos os critérios possíveis
                    let predicate = NSPredicate(value: true)  // Busca todos os registros
                    let query = CKQuery(recordType: RecordType.activity.rawValue, predicate: predicate)
                    
                    do {
                        let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                        
                        print("FILHO: Encontrados \(results.count) registros na zona \(zone.zoneID.zoneName)")
                        
                        for result in results {
                            switch result.1 {
                            case .success(let record):
                                print("FILHO: Registro encontrado, ID: \(record.recordID.recordName)")
                                print("FILHO: Campos: \(record.allKeys().map { "\($0): \(String(describing: record[$0]))" }.joined(separator: ", "))")
                                
                                // Verificar se o registro tem kidID ou kidReference que corresponda
                                let recordKidID = record["kidID"] as? String
                                let recordKidRef = record["kidReference"] as? CKRecord.Reference
                                
                                if recordKidID == kidID || recordKidRef?.recordID.recordName == kidID {
                                    print("FILHO: Registro corresponde ao kidID!")
                                    if let activity = ActivitiesRegister(record: record) {
                                        allActivities.append(activity)
                                    }
                                }
                            case .failure(let error):
                                print("FILHO: Erro ao processar registro: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("FILHO: Erro ao buscar na zona \(zone.zoneID.zoneName): \(error.localizedDescription)")
                    }
                }
                
                // Após varrer todas as zonas, vamos inspecionar completamente o banco compartilhado
                print("FILHO: Solicitando inspeção completa do banco compartilhado")
                await cloudService.inspectSharedDatabase()
                
                // Processar todas as atividades encontradas
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if allActivities.isEmpty {
                        self.feedbackMessage = "Nenhuma atividade encontrada"
                        self.activities = []
                        print("FILHO: Nenhuma atividade encontrada em nenhuma zona")
                        return
                    }
                    
                    print("FILHO: Encontradas \(allActivities.count) atividades no total")
                    
                    // Filtra atividades para hoje
                    let calendar = Calendar.current
                    self.activities = allActivities.filter { activity in
                        let isToday = calendar.isDateInToday(activity.date)
                        print("FILHO: Atividade \(activity.activityID) é hoje? \(isToday)")
                        return isToday
                    }
                    
                    print("FILHO: Após filtrar por hoje, restaram \(self.activities.count) atividades")
                    
                    self.feedbackMessage = self.activities.isEmpty
                        ? "Nenhuma atividade para hoje"
                        : "✅ Encontradas \(self.activities.count) atividades para hoje"
                }
            } catch {
                print("FILHO: Erro ao listar zonas: \(error.localizedDescription)")
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
