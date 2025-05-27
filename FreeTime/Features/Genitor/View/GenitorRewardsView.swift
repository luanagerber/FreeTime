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
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(alignment: .leading) {
            
            Text("Histórico")
                .font(.custom("SF Pro", size: 34, relativeTo: .largeTitle))
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            Text("Confira as recompensas da criança e marque quando forem entregues.")
                .font(.custom("SF Pro", size: 15, relativeTo: .body))
            
            HStack {
                Text("Saldo da criança")
                
                Spacer()
                
                Text("25")
                
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
                
                if viewModel.rewards.isEmpty {
                    VStack(alignment: .center, spacing: 10) {
                        Text("Nenhuma recompensa registrada")
                            .font(.custom("SF Pro", size: 17, relativeTo: .headline))
                            .fontWeight(.medium)
                        
                        Text("Todas as recompensas resgatadas pela criança na lojinha serão exibidas aqui")
                            .font(.custom("SF Pro", size: 15, relativeTo: .subheadline))
                            .multilineTextAlignment(.center)
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
                                }
                            }
                            
                        }
                        .padding(.bottom, 20)
                    }
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
        .refreshable {
            viewModel.isRefreshing = true
            try? await Task.sleep(nanoseconds: 2_000_000_000) // simula delay de 1s
            viewModel.isRefreshing = false
        }
    }
}

#Preview {
    GenitorRewardsView()
}
