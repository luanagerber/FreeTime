//
//  KidManagementView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct KidManagementView: View {
    
    @EnvironmentObject var coordinator: Coordinator
    @EnvironmentObject var invitationManager: InvitationStatusManager
    @EnvironmentObject var firstLaunchManager: FirstLaunchManager
    
    
    @StateObject private var viewModel = GenitorViewModel.shared
    @State private var hasSharedSuccessfully = false
    @State private var showingShareConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Adicionar Criança")
                    .font(.system(size: 34, weight: .semibold))
                    .padding()
                
                // Show add child section if no kids, otherwise show share section
                if viewModel.kids.isEmpty {
                    addChildSection
                } else {
                    shareSection
                }
                
                Spacer()
                
                // Botão só aparece após compartilhamento bem-sucedido
//                if canShowNextButton {
//                    Button("Próxima") {
//                        goToNextView()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .padding(.bottom)
//                }
                
                // Debug info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info:")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("Invitation Status: \(invitationManager.currentStatus.rawValue)")
                        .font(.caption2)
                    Text("Kids Count: \(viewModel.kids.count)")
                        .font(.caption2)
                    Text("Initial Setup Complete: \(firstLaunchManager.hasCompletedInitialSetup ? "Yes" : "No")")
                        .font(.caption2)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
            .onAppear {
                viewModel.setupCloudKit()
                checkExistingShareState()
            }
            .sheet(isPresented: $viewModel.sharingSheet, onDismiss: {
                // Quando o sheet fechar, verifica se o compartilhamento foi feito
                invitationManager.updateStatus(to: .sent)
                hasSharedSuccessfully = true
                showingShareConfirmation = true
            }) {
                if let shareView = viewModel.shareView {
                    shareView
                } else {
                    Text("Preparando compartilhamento...")
                }
            }
            .alert("Compartilhamento Enviado!", isPresented: $showingShareConfirmation) {
                Button("OK") { goToNextView() }
            } message: {
                Text("O link foi compartilhado com sucesso. Agora você pode prosseguir.")
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canShowNextButton: Bool {
        // Se não for o primeiro acesso E já tem status sent, mostra o botão
        if !firstLaunchManager.hasCompletedInitialSetup {
            // No primeiro acesso, só mostra após compartilhar com sucesso
            return hasSharedSuccessfully
        } else {
            // Nos acessos subsequentes, mostra se tem status sent ou se compartilhou
            return invitationManager.currentStatus == .sent || hasSharedSuccessfully
        }
    }
    
    // MARK: - View Components
    
    private var addChildSection: some View {
        VStack(alignment: .center, spacing: 16) {
            TextField("Nome da criança", text: $viewModel.childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Adicionar Criança") {
                viewModel.addChild()
            }
            .disabled(viewModel.childName.isEmpty || viewModel.isLoading || !viewModel.zoneReady)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var shareSection: some View {
        VStack(alignment: .center, spacing: 16) {
            if let firstKid = viewModel.kids.first {
                Text("Criança: \(firstKid.name)")
                    .font(.headline)
                
                if !hasSharedSuccessfully {
                    Button("Compartilhar Link") {
                        viewModel.selectedKid = firstKid
                        viewModel.shareKid(firstKid)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                } else {
                    Label("Link Compartilhado", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Methods
    
    private func checkExistingShareState() {
        // Se não é o primeiro acesso e tem status sent, marca como já compartilhado
        if firstLaunchManager.hasCompletedInitialSetup && invitationManager.currentStatus == .sent {
            hasSharedSuccessfully = true
        }
    }
    
    func goToNextView() {
        // Marca que completou o setup inicial antes de navegar
        if !firstLaunchManager.hasCompletedInitialSetup {
            firstLaunchManager.completeInitialSetup()
        }
        
        coordinator.push(.genitorHome)
    }
}

#Preview {
    KidManagementView()
        .environmentObject(Coordinator())
        .environmentObject(InvitationStatusManager.shared)
}
