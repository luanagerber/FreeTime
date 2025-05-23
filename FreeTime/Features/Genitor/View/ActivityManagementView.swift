//
//  ActivityManagementView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct ActivityManagementView: View {

    @StateObject private var viewModel = GenitorViewModel.shared
    
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
                    } else if !viewModel.isLoading && viewModel.zoneReady {
                        emptyStateView
                    }
                    
                    if viewModel.isLoading {
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
        Button(action: viewModel.refresh) {
            Label("Atualizar dados", systemImage: "arrow.clockwise")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .disabled(viewModel.isLoading)
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
                    
                    Button("Atribuir Atividade") {
                        viewModel.selectedKid = kid
                        viewModel.showActivitySelector = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
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
}

#Preview {
    ActivityManagementView()
}

