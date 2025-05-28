//
//  KidManagementView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct KidManagementView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var coordinator: Coordinator
    @EnvironmentObject var invitationManager: InvitationStatusManager
    @EnvironmentObject var firstLaunchManager: FirstLaunchManager
    
    // MARK: - View Model
    @StateObject private var viewModel = GenitorViewModel.shared
    
    // MARK: - View State
    @State private var hasSharedSuccessfully = false
    @State private var showingShareConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                
                if viewModel.hasKids {
                    shareSection
                } else {
                    addChildSection
                }
                
                Spacer()
                
                if isDebugMode {
                    debugInfoView
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
            .onAppear(perform: handleOnAppear)
            .sheet(isPresented: $viewModel.sharingSheet, onDismiss: handleShareSheetDismiss) {
                shareSheetContent
            }
            .alert("Compartilhamento enviado!", isPresented: $showingShareConfirmation) {
                Button("OK") { navigateToNextView() }
            } message: {
                Text("O link foi compartilhado com sucesso. Agora você pode prosseguir.")
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        Text("Adicionar Criança")
            .font(.system(size: 34, weight: .semibold))
            .padding()
    }
    
    private var addChildSection: some View {
        VStack(alignment: .center, spacing: 16) {
            TextField("Nome da criança", text: $viewModel.childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Adicionar Criança") {
                viewModel.addChild()
            }
            .disabled(!viewModel.canAddChild)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var shareSection: some View {
        VStack(alignment: .center, spacing: 16) {
            if let firstKid = viewModel.firstKid {
                Text("Criança: \(firstKid.name)")
                    .font(.headline)
                
                if viewModel.shouldShowShareButton(hasSharedSuccessfully: hasSharedSuccessfully) {
                    shareButton
                } else if viewModel.shouldShowShareConfirmation(hasSharedSuccessfully: hasSharedSuccessfully) {
                    shareConfirmationLabel
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var shareButton: some View {
        Button("Compartilhar Link") {
            viewModel.prepareKidSharing()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canShareKid)
    }
    
    private var shareConfirmationLabel: some View {
        Label("Link compartilhado", systemImage: "checkmark.circle.fill")
            .foregroundColor(.green)
            .font(.subheadline)
    }
    
    private var shareSheetContent: some View {
        Group {
            if let shareView = viewModel.shareView {
                shareView
            } else {
                Text("Preparando compartilhamento...")
            }
        }
    }
    
    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug Info:")
                .font(.caption2)
                .fontWeight(.bold)
            
            // Navigation related debug info
            Text("Invitation Status: \(invitationManager.currentStatus.rawValue)")
                .font(.caption2)
            Text("Initial Setup Complete: \(firstLaunchManager.hasCompletedInitialSetup ? "Yes" : "No")")
                .font(.caption2)
            Text("Has Shared Successfully: \(hasSharedSuccessfully ? "Yes" : "No")")
                .font(.caption2)
            
            // ViewModel debug info
            ForEach(viewModel.debugInfo, id: \.label) { info in
                Text("\(info.label): \(info.value)")
                    .font(.caption2)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - View Lifecycle Methods
    
    private func handleOnAppear() {
        viewModel.setupCloudKit()
        checkExistingShareState()
    }
    
    private func handleShareSheetDismiss() {
        // Update navigation state when share sheet is dismissed
        invitationManager.updateStatus(to: .sent)
        hasSharedSuccessfully = true
        showingShareConfirmation = true
    }
    
    // MARK: - Navigation Methods
    
    private func checkExistingShareState() {
        // Check if should mark as already shared based on navigation state
        if firstLaunchManager.hasCompletedInitialSetup &&
           viewModel.checkShareState(for: invitationManager.currentStatus) {
            hasSharedSuccessfully = true
        }
    }
    
    private func navigateToNextView() {
        // Handle navigation state before navigating
        if !firstLaunchManager.hasCompletedInitialSetup {
            firstLaunchManager.completeInitialSetup()
        }
        
        coordinator.push(.genitorHome)
    }
}

// MARK: - Preview

#Preview {
    KidManagementView()
        .environmentObject(Coordinator())
        .environmentObject(InvitationStatusManager.shared)
        .environmentObject(FirstLaunchManager.shared)
}
