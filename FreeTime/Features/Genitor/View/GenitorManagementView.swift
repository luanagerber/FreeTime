//
//  GenitorManagementView.swift
//  FreeTime
//
//  Created by Thales Araújo on 28/05/25.
//

import SwiftUI

struct GenitorManagementView: View {
    
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
            ZStack {
                Color("backgroundGenitorShared")
                
                VStack {
                    if viewModel.hasKids {
                        ShareView()
                    } else {
                        AddChildView()
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                }
                .background(
                    RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                        .fill(Color("backgroundGenitor")) // fundo branco
                )
                .overlay(
                    RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 5) // borda cinza
                )
                .clipShape(
                    RoundedCorner(radius: 32, corners: [.topLeft, .topRight]) // recorte final
                )
                .vSpacing(.bottom)
                .onAppear(perform: handleOnAppear)
                .sheet(isPresented: $viewModel.sharingSheet, onDismiss: handleShareSheetDismiss) {
                    shareSheetContent
                }
                .alert("Link enviado!", isPresented: $showingShareConfirmation) {
                    Button("Continuar") { navigateToNextView() }
                } message: {
                    Text("Assim que sua criança acessar o link no iPad, tudo ficará conectado.")
                }
                .refreshable {
                    viewModel.refresh()
                }
                
                
            }
            .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    func AddChildView() -> some View {
       // ScrollView {
            VStack {
                #warning("Utilização do ImageResource para evitar erros com nome de imagem.")
                Image("imageAddChild")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width * 0.205,
                        height: UIScreen.main.bounds.height * 0.094
                    )
                    .padding(.bottom, 50)
                    .padding(.top, 80)
                
                VStack(alignment: .leading) {
                    Text("Criar perfil da criança")
                        .font(.custom("SF Pro", size: 28, relativeTo: .title2))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("primaryColor"))
                        .padding(.bottom, 10)
                    
                    Text("Informe o nome da criança para criar o perfil e iniciar a conexão.")
                        .font(.custom("SF Pro", size: 15, relativeTo: .callout))
                        .foregroundStyle(Color("primaryColor"))
                        .padding(.bottom, 30)
                    
                    TextField("Nome da criança", text: $viewModel.childName)
                        .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    //                    .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color("primaryColor").opacity(0.4))
                        .hSpacing(.leading)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 70)
                
                Button(action: {
                    viewModel.addChild()
                }, label: {
                    HStack {
                        Text("Salvar")
                    }
                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.canAddChild
                                     ? Color("primaryColor")
                                     : Color("primaryColor").opacity(0.4)
                    )
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.canAddChild
                                ? Color("backgroundTaskButtonSave")
                                : Color("backgroundTaskButtonSave").opacity(0.4)
                    )
                    .cornerRadius(40)
                    
                })
                .disabled(!viewModel.canAddChild)
                .padding(.bottom, 100)
                .padding(.horizontal, 20)
                
            }
            .background(Color("backgroundGenitor"))
            .padding(.top, 32)
            
        //}
        //.keyboardAdaptive()
        
    }
    
    @ViewBuilder
    func ShareView() -> some View {
        VStack {
            if viewModel.firstKid != nil {
                Image("imageShareLink")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width * 0.205,
                        height: UIScreen.main.bounds.height * 0.094
                    )
                    .padding(.bottom, 50)
                    .padding(.top, 80)
                
                Text("Enviar link de conexão")
                    .font(.custom("SF Pro", size: 28, relativeTo: .title2))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("primaryColor"))
                    .padding(.bottom, 10)
                    .padding(.horizontal, 30)
                    .hSpacing(.leading)
                
                Text("Compartilhe o link de conexão com sua criança. Ela precisará baixar o app no iPad para receber as atividades que você criar por aqui.")
                    .font(.custom("SF Pro", size: 15, relativeTo: .callout))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("primaryColor"))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 70)
                    .padding(.horizontal, 30)
                
                shareButton
                    .disabled(hasSharedSuccessfully ? true : false)
                    .padding(.bottom, 60)
                
            }
        }
        .background(Color("backgroundGenitor"))
    }
    
    private var shareButton: some View {
        Button(action: {
            viewModel.prepareKidSharing()
        }, label: {
            HStack {
                Text("Compartilhar link")
            }
            .font(.custom("SF Pro", size: 17, relativeTo: .body))
            .fontWeight(.bold)
            .foregroundColor(viewModel.canShareKid
                             ? Color("primaryColor")
                             : Color("primaryColor").opacity(0.4)
            )
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(viewModel.canShareKid
                        ? Color("backgroundTaskButtonSave")
                        : Color("backgroundTaskButtonSave").opacity(0.4)
            )
            .cornerRadius(40)
            
        })
        .disabled(!viewModel.canShareKid)
        .padding(.bottom, 100)
        .padding(.horizontal, 20)
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
    
    private var feedbackMessageView: some View {
        Text(viewModel.feedbackMessage)
            .padding()
            .background(
                viewModel.feedbackMessage.contains("❌") ? Color.red.opacity(0.1) :
                    viewModel.feedbackMessage.contains("✅") ? Color.green.opacity(0.1) :
                    Color.blue.opacity(0.1)
            )
            .cornerRadius(8)
            .foregroundColor(
                viewModel.feedbackMessage.contains("❌") ? .red :
                    viewModel.feedbackMessage.contains("✅") ? .green :
                        .blue
            )
    }
    
    //    private var debugInfoView: some View {
    //        VStack(alignment: .leading, spacing: 4) {
    //            Text("Debug Info:")
    //                .font(.caption2)
    //                .fontWeight(.bold)
    //
    //            // Navigation related debug info
    //            Text("Invitation Status: \(invitationManager.currentStatus.rawValue)")
    //                .font(.caption2)
    //            Text("Initial Setup Complete: \(firstLaunchManager.hasCompletedInitialSetup ? "Yes" : "No")")
    //                .font(.caption2)
    //            Text("Has Shared Successfully: \(hasSharedSuccessfully ? "Yes" : "No")")
    //                .font(.caption2)
    //
    //            // ViewModel debug info
    //            ForEach(viewModel.debugInfo, id: \.label) { info in
    //                Text("\(info.label): \(info.value)")
    //                    .font(.caption2)
    //            }
    //        }
    //        .padding(8)
    //        .background(Color.gray.opacity(0.1))
    //        .cornerRadius(8)
    //    }
    
    
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

#Preview {
    GenitorManagementView()
        .environmentObject(FirstLaunchManager())
}
