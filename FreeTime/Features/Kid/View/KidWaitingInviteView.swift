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
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 100))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Aguardando Convite")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Você ainda não recebeu o convite do seu responsável. Quando receber um convite, abra-o em seu dispositivo para acessar suas atividades.")
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
                .padding(.horizontal, 70)
                .font(.system(size: 23))
            
            // Botão de refresh

//            Button(action: nextView) {
//                Label("Próxima Tela", systemImage: "arrowshape.right.circle")

            Button(action: kidViewModel.refresh) {
                Label("Atualizar dados", systemImage: "arrow.clockwise")
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .cornerRadius(8)
            }
            .disabled(kidViewModel.isLoading)
            
            Text(kidViewModel.feedbackMessage)
                .foregroundColor(.secondary)
                .font(.system(size: 17, weight: .bold))
            
            if kidViewModel.isLoading {
                ProgressView()
                    .padding()
            }

            
        }
        .padding(.vertical, 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 200)
        .refreshable {
            if kidViewModel.hasAcceptedShareLink {
                goToNextView()
            }
        }
        .onAppear {
            kidViewModel.checkForSharedKid()
        }
        
    }
    
    private func goToNextView() {
        coordinator.push(.kidHome)
    }

}


#Preview("WaitingInvite") {
    CoordinatorView()
}
