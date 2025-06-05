//
//  GenitorRewardsView.swift
//  FreeTime
//
//  Created by Thales Araújo on 22/05/25.
//

import SwiftUI

struct GenitorRewardsView: View {
    
    @ObservedObject var viewModel = GenitorViewModel.shared
    @ObservedObject var coinManager = CoinManager.shared
    
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        VStack() {
            HeaderView()
            RewardsView()
        }
        .vSpacing(.top)
        .onAppear {
            if !hasLoadedInitialData {
                viewModel.setupCloudKit()
                viewModel.loadRewardsFromKid()
                viewModel.setupCoinManager()
                hasLoadedInitialData = true
            }
        }
        .refreshable {
            await refreshData()
        }
        .background(Color("backgroundGenitor"))
    }
    
    private func saveRewardUpdate(_ reward: CollectedReward) {
        viewModel.toggleRewardDeliveryStatus(reward)
    }
    
    @MainActor
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.loadRewardsFromKid()
            viewModel.setupCoinManager()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(alignment: .leading) {
            
            Text("Histórico")
                .font(.system(size: 34, weight: .semibold))
                .padding(.bottom, 10)
                .padding(.top, 15)
                .foregroundStyle(Color("primaryColor"))
            
            Text("Confira as recompensas da criança e marque quando forem entregues.")
                .font(.custom("SF Pro", size: 15, relativeTo: .body))
                .foregroundStyle(Color("primaryColor"))
                        
            HStack {
                Text("Saldo da criança")
                
                Spacer()
                
                if coinManager.isLoading && coinManager.kidCoins == 0 {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(coinManager.kidCoins)")
                        .animation(.easeInOut(duration: 0.3), value: coinManager.kidCoins)
                }
                
                Image(systemName: "dollarsign.circle.fill")
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color("primaryColor").opacity(0.6))
            .padding()
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("BackgroundHeaderCoins"))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                }
            }
            .cornerRadius(10)
            .padding(.top, 20)
        }
        .hSpacing(.leading)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    func RewardsView() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                
                if viewModel.refreshFailed {
                    
                    VStack (spacing: 5) {
                        Text("Algo deu errado")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.text)
                        
                        Text("Não foi possível carregar os dados. \nTente novamente mais tarde")
                            .font(.custom("SF Pro", size: 15, relativeTo: .subheadline))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.text)
                    }
                    .padding(.vertical, 171)
                    
                } else {
                    if viewModel.isLoading && viewModel.rewards.isEmpty {
                        VStack {
                            ProgressView()
                            Text("Carregando recompensas...")
                                .font(.custom("SF Pro", size: 15, relativeTo: .subheadline))
                                .foregroundStyle(Color("primaryColor").opacity(0.6))
                                .padding(.top, 10)
                        }
                        .padding(.vertical, 100)
                    }
                    else if viewModel.rewards.isEmpty && !viewModel.isLoading {
                        VStack(alignment: .center, spacing: 10) {
                            
                            Text("Nenhuma recompensa registrada")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color("primaryColor"))
                            
                            Text("Todas as recompensas resgatadas pela criança na lojinha serão exibidas aqui")
                                .font(.custom("SF Pro", size: 15, relativeTo: .subheadline))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color("primaryColor"))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 171)
                        .padding(.top, 171)
                    }
                    
                    else {
                        ForEach(viewModel.groupedRewardsByDay, id: \.self) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.date.formattedAsDayMonth())
                                    .font(.custom("SF Pro", size: 15, relativeTo: .headline))
                                    .foregroundColor(Color("primaryColor").opacity(0.4))
                                
                                Rectangle()
                                    .fill(Color("primaryColor").opacity(0.4))
                                    .frame(height: UIScreen.main.bounds.height * 0.0014)
                                    .padding(.top, 2)
                                    .padding(.bottom, 4)
                                
                                ForEach(viewModel.rewards.indices, id: \.self) { index in
                                    let reward = viewModel.rewards[index]
                                    if Calendar.current.isDate(reward.dateCollected, inSameDayAs: group.date) {
                                        GenitorRewardsRowView(
                                            reward: $viewModel.rewards[index],
                                            onToggle: {
                                                saveRewardUpdate(reward)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .overlay {
                let borderColor = Color(red: 0.87, green: 0.87, blue: 0.87)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 2)
            }
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
    }
}

#Preview {
    GenitorRewardsView()
}
