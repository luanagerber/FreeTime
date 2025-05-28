//
//  WaitingShareView.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 21/05/25.
//

import SwiftUI
import CloudKit

struct KidWaitingInviteView: View {
    
    @EnvironmentObject var coordinator: Coordinator
    @StateObject private var kidViewModel = KidViewModel()
    
    var body: some View {
        ZStack{
            Image("kidWaitingInvite")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack(){
                ZStack() {
                    VStack(alignment: .leading){
                        ZStack(alignment: .leading){
                            Rectangle()
                                .fill(.message)
                                .frame(height: 100)
                                .cornerRadius(15)
                            
                            Text("Aguardando convite...")
                                .foregroundStyle(.primary)
                                .font(.system(size: 28))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 42)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 30) {
                        
                        
                        Text("Você ainda não recebeu o convite do seu responsável!")
                            .foregroundColor(.primary)
                            .font(.system(size: 23))
                        
                        Text("Assim que ele enviar, é só abrir o convite para ver suas atividades e começar a se divertir!")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                            .font(.system(size: 23))
                        
                    }.padding(.horizontal, 20)
                    .padding(.top, 64)
                    
                }
            }
            .background(Color.white.opacity(1.0))
            .cornerRadius(15)
            //.padding(.vertical, 314)
            //.padding(.horizontal, 420)
            .refreshable {
                kidViewModel.checkForSharedKid()
                if kidViewModel.hasAcceptedShareLink {
                    goToNextView()
                }
            }
            .onAppear {
                kidViewModel.checkForSharedKid()
            }
            .onChange(of: kidViewModel.hasAcceptedShareLink) { hasAccepted in
                if hasAccepted {
                    goToNextView()
                }
            }
            .alert("Erro", isPresented: $kidViewModel.showError) {
                Button("OK") {
                    kidViewModel.clearError()
                }
            } message: {
                Text(kidViewModel.errorMessage)
            }
        }
    }
    
    private func goToNextView() {
        coordinator.push(.kidHome)
    }
}

#Preview("WaitingInvite") {
    CoordinatorView()
}
