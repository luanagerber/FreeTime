//
//  ChildManagementView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct KidManagementView: View {

    @StateObject private var viewModel = GenitorViewModel.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    debugButtons
                    
                    Text("Gerenciar Crianças")
                        .font(.title)
                        .padding()
                    
                    refreshButton
                    
                    addChildSection
                    
                    if !viewModel.kids.isEmpty {
                        kidsListSection
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
                                        
                    Spacer()
                }
                .padding()
                .onAppear {
                    viewModel.setupCloudKit()
                }
                .sheet(isPresented: $viewModel.sharingSheet) {
                    if let shareView = viewModel.shareView {
                        shareView
                    } else {
                        Text("Preparando compartilhamento...")
                    }
                }
            }
            .navigationTitle("Gerenciar Crianças")
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
    
    private var addChildSection: some View {
        VStack(alignment: .leading) {
            Text("Adicionar nova criança")
                .font(.headline)
            
            TextField("Nome da criança", text: $viewModel.childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 8)
            
            Button("Adicionar Criança") {
                viewModel.addChild()
            }
            .disabled(viewModel.childName.isEmpty || viewModel.isLoading || !viewModel.zoneReady)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var kidsListSection: some View {
        VStack(alignment: .leading) {
            Text("Suas Crianças")
                .font(.headline)
            
            List(viewModel.kids, id: \.id) { kid in
                HStack {
                    Text(kid.name)
                    Spacer()
                    
                    Button("Compartilhar") {
                        viewModel.selectedKid = kid
                        viewModel.shareKid(kid)
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
        Text("Nenhuma criança cadastrada. Adicione uma criança usando o formulário acima.")
            .foregroundColor(.secondary)
            .padding()
            .multilineTextAlignment(.center)
    }
    
    private var feedbackMessageView: some View {
        Text(viewModel.feedbackMessage)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    KidManagementView()
}
