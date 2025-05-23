//
//  ChildManagementView.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

struct KidManagementView: View {
    
    @EnvironmentObject var coordinator: Coordinator
    
    @StateObject private var viewModel = GenitorViewModel.shared
    
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
                
                Button("Próxima View"){
                    goToNextView()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.shouldNavigateToNextView)
                .padding(.bottom)
                
                // Feedback message at the bottom
//                if !viewModel.feedbackMessage.isEmpty {
//                    feedbackMessageView
//                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
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
                
                Button("Compartilhar Link") {
                    viewModel.selectedKid = firstKid
                    viewModel.shareKid(firstKid)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var feedbackMessageView: some View {
        Text(viewModel.feedbackMessage)
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
    }
    
    func goToNextView() {
        coordinator.push(.genitorHome)
    }
}

#Preview {
    KidManagementView()
}
