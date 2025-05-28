//
//  GenitorRewardsView.swift
//  FreeTime
//
//  Created by Thales Araújo on 22/05/25.
//

import SwiftUI

struct GenitorRewardsView: View {
    
    @StateObject var viewModel = GenitorViewModel.shared
    
    var body: some View {
        VStack() {
            
            HeaderView()
            
            RewardsView()
            
        }
        .vSpacing(.top)
        .onAppear {
            viewModel.setupCloudKit()
            loadRewards()
        }
        .refreshable {
            loadRewards()
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(alignment: .leading) {
            
            Text("Histórico")
                .font(.custom("SF Pro", size: 34, relativeTo: .largeTitle))
                .fontWeight(.semibold)
                .padding(.bottom, 10)
                .foregroundStyle(Color("primaryColor"))
            
            Text("Confira as recompensas da criança e marque quando forem entregues.")
                .font(.custom("SF Pro", size: 15, relativeTo: .body))
                .foregroundStyle(Color("primaryColor"))
            
            HStack {
                Text("Saldo da criança")
                
                Spacer()
                
                // Calcular saldo atual da criança
                let currentBalance = calculateCurrentBalance()
                Text("\(currentBalance)")
                
                Image(systemName: "dollarsign.circle.fill")
            }
            .font(.custom("SF Pro", size: 17, relativeTo: .body))
            .fontWeight(.medium)
            .textScale(.secondary)
            .foregroundStyle(.gray)
            .padding()
            .background {
                Rectangle()
                    .foregroundStyle(.clear)
                    .background(.backgroundHeaderCoins)
                    .cornerRadius(10)
                
            }
            .padding(.top, 20)
            
            
        }
        .hSpacing(.leading)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    func RewardsView() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                
                if viewModel.rewards.isEmpty && !viewModel.isLoading {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "gift")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Text("Nenhuma recompensa registrada")
                            .font(.custom("SF Pro", size: 17, relativeTo: .headline))
                            .fontWeight(.medium)
                        
                        Text("Todas as recompensas resgatadas pela criança na lojinha serão exibidas aqui")
                            .font(.custom("SF Pro", size: 15, relativeTo: .subheadline))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 171)
                    .padding(.top, 171)
                } else {
                    ForEach(viewModel.groupedRewardsByDay, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.date.formattedAsDayMonth())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Divider()
                                .padding(.bottom, 4)
                            
                            // Atualização dos isDelivered nas rewards da ViewModel
                            ForEach(viewModel.rewards.indices, id: \.self) { index in
                                let reward = viewModel.rewards[index]
                                if Calendar.current.isDate(reward.dateCollected, inSameDayAs: group.date) {
                                    GenitorRewardsRowView(reward: $viewModel.rewards[index])
                                        .onTapGesture {
                                            // Salvar alterações no CloudKit quando o status muda
                                            saveRewardUpdate(reward)
                                        }
                                }
                            }
                            
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 0.5)
                    .stroke(lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
    }
    
    private func loadRewards() {
        guard let kidID = viewModel.firstKid?.id?.recordName else { return }
        
        viewModel.isLoading = true
        
        CloudService.shared.fetchAllCollectedRewards(forKid: kidID) { result in
            DispatchQueue.main.async {
                viewModel.isLoading = false
                switch result {
                case .success(let rewards):
                    viewModel.rewards = rewards
                case .failure(let error):
                    print("Erro ao carregar recompensas: \(error)")
                    viewModel.rewards = []
                }
            }
        }
    }
    
    private func saveRewardUpdate(_ reward: CollectedReward) {
        CloudService.shared.updateCollectedReward(reward, isShared: false) { result in
            switch result {
            case .success:
                print("Recompensa atualizada com sucesso")
            case .failure(let error):
                print("Erro ao atualizar recompensa: \(error)")
            }
        }
    }
    
    private func calculateCurrentBalance() -> Int {
        // Implementar lógica para calcular saldo atual baseado nas atividades completadas
        // menos as recompensas resgatadas
        return 25 // Valor temporário
    }
}

#Preview {
    GenitorRewardsView()
}
