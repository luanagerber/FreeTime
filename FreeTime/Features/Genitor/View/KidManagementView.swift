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
    
    @StateObject private var viewModel = GenitorViewModel.shared
    @State private var hasSharedSuccessfully = false
    
    @State private var isSharing = false
    @State private var shareCompleted = false
    @State private var sharedURL: URL? = nil

    
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
                if hasSharedSuccessfully || invitationManager.currentStatus == .sent {
                    Button("Próxima") {
                        goToNextView()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
                
                // Debug info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info:")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("Invitation Status: \(invitationManager.currentStatus.rawValue)")
                        .font(.caption2)
                    Text("Has Shared: \(hasSharedSuccessfully ? "Yes" : "No")")
                        .font(.caption2)
                    Text("Kids Count: \(viewModel.kids.count)")
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
                // Se já foi compartilhado anteriormente, mostra o botão
                if invitationManager.currentStatus == .sent {
                    hasSharedSuccessfully = true
                }
            }
            .sheet(isPresented: $viewModel.sharingSheet, onDismiss: {
                // Quando o sheet de compartilhamento fechar, marca como compartilhado
                if invitationManager.currentStatus == .sent {
                    hasSharedSuccessfully = true
                }
            }) {
                if let shareView = viewModel.shareView {
                    shareView
                } else {
                    Text("Preparando compartilhamento...")
                }
            }
            .refreshable {
                viewModel.refresh()
            }
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
    
    func goToNextView() {
        coordinator.push(.rewardsStoreDebug)
    }
}

#Preview {
    KidManagementView()
        .environmentObject(Coordinator())
        .environmentObject(InvitationStatusManager.shared)
}
