//
//  ActivityManagementDebugView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct ActivityManagementDebugView: View {
    @EnvironmentObject var coordinator: Coordinator
    @StateObject private var viewModel = GenitorViewModel.shared
    @State private var selectedKidActivities: [ActivitiesRegister] = []
    @State private var isLoadingActivities = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    debugButtons
                    
                    Text("Gerenciar Atividades")
                        .font(.title)
                        .padding()
                    
                    refreshButton
                    
                    if !viewModel.kids.isEmpty {
                        kidsActivitiesSection
                        
                        if viewModel.selectedKid != nil {
                            registeredActivitiesSection
                        }
                    } else if !viewModel.isLoading && viewModel.zoneReady {
                        emptyStateView
                    }
                    
                    if viewModel.isLoading || isLoadingActivities {
                        ProgressView()
                            .padding()
                    }
                    
                    if !viewModel.feedbackMessage.isEmpty {
                        feedbackMessageView
                    }
                    
                    changeRoleButton
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    viewModel.setupCloudKit()
                }
                .sheet(isPresented: $viewModel.showActivitySelector) {
                    activitySelectorView
                }
            }
            .navigationTitle("Gerenciar Atividades")
            .refreshable {
                viewModel.refresh()
                if let selectedKid = viewModel.selectedKid {
                    loadActivities(for: selectedKid)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var debugButtons: some View {
        VStack(spacing: 10) {
            Button("🗑️ RESETAR APP") {
                viewModel.resetAllData()
            }
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.red)
            
            Button("🔍 Debug Banco Compartilhado") {
                viewModel.debugSharedDatabase()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            viewModel.refresh()
            if let selectedKid = viewModel.selectedKid {
                loadActivities(for: selectedKid)
            }
        }) {
            Label("Atualizar dados", systemImage: "arrow.clockwise")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .disabled(viewModel.isLoading || isLoadingActivities)
    }
    
    private var kidsActivitiesSection: some View {
        VStack(alignment: .leading) {
            Text("Suas Crianças")
                .font(.headline)
            
            List(viewModel.kids, id: \.id) { kid in
                HStack {
                    VStack(alignment: .leading) {
                        Text(kid.name)
                            .font(.headline)
                        Text("Toque para gerenciar atividades")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button("Ver Atividades") {
                            viewModel.selectedKid = kid
                            loadActivities(for: kid)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Atribuir Nova") {
                            viewModel.selectedKid = kid
                            viewModel.showActivitySelector = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: CGFloat(viewModel.kids.count * 80).clamped(to: 100...300))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var registeredActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Atividades de \(viewModel.selectedKid?.name ?? "")")
                    .font(.headline)
                Spacer()
                Text("\(selectedKidActivities.count) atividades")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if selectedKidActivities.isEmpty && !isLoadingActivities {
                Text("Nenhuma atividade registrada ainda")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(selectedKidActivities, id: \.id) { activityRegister in
                            ActivityRowView(activityRegister: activityRegister)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Nenhuma criança encontrada")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Você precisa adicionar crianças primeiro na seção 'Gerenciar Crianças' antes de poder atribuir atividades.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var feedbackMessageView: some View {
        Text(viewModel.feedbackMessage)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var changeRoleButton: some View {
        Button("Trocar papel") {
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var activitySelectorView: some View {
        NavigationView {
            VStack {
                // Activity list
                List(Activity.catalog, id: \.id) { activity in
                    Button(action: {
                        viewModel.selectedActivity = activity
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
                            if viewModel.selectedActivity?.id == activity.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Date and duration selectors
                DatePicker("Data e hora", selection: $viewModel.scheduledDate)
                    .padding()
                
                Picker("Duração", selection: $viewModel.duration) {
                    Text("30 minutos").tag(TimeInterval(1800))
                    Text("1 hora").tag(TimeInterval(3600))
                    Text("1 hora e 30 minutos").tag(TimeInterval(5400))
                    Text("2 horas").tag(TimeInterval(7200))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Schedule button
                Button("Agendar Atividade") {
                    viewModel.scheduleActivity()
                }
                .disabled(viewModel.selectedActivity == nil || viewModel.selectedKid == nil)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            .navigationTitle("Selecionar Atividade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        viewModel.showActivitySelector = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadActivities(for kid: Kid) {
        guard let kidID = kid.id?.recordName else { return }
        
        isLoadingActivities = true
        CloudService.shared.fetchAllActivities(forKid: kidID) { result in
            DispatchQueue.main.async {
                isLoadingActivities = false
                switch result {
                case .success(let activities):
                    selectedKidActivities = activities
                case .failure(let error):
                    print("Erro ao carregar atividades: \(error)")
                    selectedKidActivities = []
                }
            }
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activityRegister: ActivitiesRegister
    
    private var activity: Activity? {
        activityRegister.activity
    }
    
    private var statusIcon: String {
        switch activityRegister.registerStatus {
        case .notCompleted:
            return "clock"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch activityRegister.registerStatus {
        case .notCompleted:
            return .green
        case .completed:
            return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity?.name ?? "Atividade Desconhecida")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(activityRegister.date, style: .date)
                    Text("•")
                    Text(activityRegister.date, style: .time)
                    Text("•")
                    Text(formatDuration(activityRegister.duration))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activityRegister.registerStatus.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Extensions

extension RegisterStatus {
    var displayName: String {
        switch self {
        case .notCompleted:
            return "Agendada"
        case .completed:
            return "Concluída"
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    ActivityManagementDebugView()
}
