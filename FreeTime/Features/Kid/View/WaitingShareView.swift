//
//  WaitingShareView.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 21/05/25.
//

import SwiftUI

struct WaitingShareView: View {
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
            Button(action: refresh) {
                Label("Atualizar dados", systemImage: "arrow.clockwise")
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .cornerRadius(8)
            }
            //.disabled(isLoading)
            
//            if isLoading {
//                ProgressView()
//                    .padding()
//            }
            
            
        }
        .padding(.vertical, 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 200)
        
    }
    
    private func refresh() {
        checkForSharedKid()
    }
    
    private func checkForSharedKid() {
//        guard let rootRecordID = cloudService.getRootRecordID() else {
//            feedbackMessage = "Nenhum convite aceito ainda"
//            return
//        }
//        
//        isLoading = true
//        feedbackMessage = "Verificando convite aceito..."
//        
//        cloudService.fetchKid(withRecordID: rootRecordID) { result in
//            DispatchQueue.main.async {
//                self.isLoading = false
//                
//                switch result {
//                    case .success(let sharedKid):
//                        self.kid = sharedKid
//                        self.feedbackMessage = "✅ Conectado como \(sharedKid.name)"
//                        // Agora carregamos as atividades
//                        self.loadActivities(for: sharedKid)
//                    case .failure(let error):
//                        self.feedbackMessage = "❌ Erro ao carregar convite: \(error)"
//                }
//            }
//        }
    }
    
}

#Preview {
    WaitingShareView()
}

