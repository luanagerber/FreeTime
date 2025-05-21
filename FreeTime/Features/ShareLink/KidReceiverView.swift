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
        
        cloudService.fetchKid(withRecordID: rootRecordID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sharedKid):
                    self.kid = sharedKid
                    self.feedbackMessage = "✅ Conectado como \(sharedKid.name)"
                    // Agora carregamos as atividades
                    self.loadActivities(for: sharedKid)
                case .failure(let error):
                    self.feedbackMessage = "❌ Erro ao carregar convite: \(error)"
                }
            }
        }
    }
    
    private func loadActivities(for kid: Kid) {
        guard let kidID = kid.id?.recordName else {
            feedbackMessage = "ID do filho não encontrado"
            return
        }
        
        isLoading = true
        feedbackMessage = "Carregando atividades..."
        
        cloudService.fetchSharedActivities(forKid: kidID) { (result: Result<[ActivitiesRegister], CloudError>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let fetchedActivities):
                    // Filtra atividades para hoje
                    let calendar = Calendar.current
                    self.activities = fetchedActivities.filter { activity in
                        calendar.isDateInToday(activity.date)
                    }
                    
                    self.feedbackMessage = self.activities.isEmpty
                        ? "Nenhuma atividade para hoje"
                        : "✅ Encontradas \(self.activities.count) atividades para hoje"
                case .failure(let error):
                    self.feedbackMessage = "❌ Erro ao carregar atividades: \(error)"
                }
            }
        }
    }
    
    private func updateActivityStatus(_ activity: ActivitiesRegister) {
        var updatedActivity = activity
        
        // Atualiza o status da atividade
        if updatedActivity.registerStatus == .notStarted {
            updatedActivity.registerStatus = .inProgress
        } else if updatedActivity.registerStatus == .inProgress {
            updatedActivity.registerStatus = .completed
        }
        
        isLoading = true
        feedbackMessage = "Atualizando status da atividade..."
        
        cloudService.updateActivity(updatedActivity, isShared: true) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.feedbackMessage = "✅ Status atualizado com sucesso"
                    
                    // Atualiza a atividade na lista
                    if let index = self.activities.firstIndex(where: { $0.id == activity.id }) {
                        self.activities[index] = updatedActivity
                    }
                    
                case .failure(let error):
                    self.feedbackMessage = "❌ Erro ao atualizar status: \(error)"
                }
            }
        }
    }
}

#Preview {
    KidReceiverView()
}
