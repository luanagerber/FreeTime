//
//  GenitorRewardsView.swift
//  FreeTime
//
//  Created by Thales Araújo on 22/05/25.
//


import SwiftUI

struct GenitorRewardsView: View {
    
    @ObservedObject var viewModel = GenitorViewModel.shared
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        VStack() {
            // Debug
            let _ = print("🎁 GenitorRewardsView - Rewards count: \(viewModel.rewards.count)")
            let _ = print("🎁 GenitorRewardsView - Is loading: \(viewModel.isLoading)")
            let _ = print("🎁 GenitorRewardsView - First kid: \(viewModel.firstKid?.name ?? "nil")")
            
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
                
                if viewModel.isLoading && viewModel.kidCoins == 0 {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(viewModel.kidCoins)")
                }
                
                Image(systemName: "dollarsign.circle.fill")
            }
            .font(.custom("SF Pro", size: 17, relativeTo: .body))
            .fontWeight(.medium)
            .foregroundStyle(Color("primaryColor").opacity(0.6))
            .padding()
            .background {
                ZStack {
                    // Fundo arredondado com a cor desejada
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("BackgroundHeaderCoins"))
                    
                    // Borda fina arredondada por cima
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
                
                // Mostrar loading inicial
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
                // Mostrar conteúdo vazio quando não há recompensas
                else if viewModel.rewards.isEmpty && !viewModel.isLoading {
                    VStack(alignment: .center, spacing: 10) {
                        
                        Text("Nenhuma recompensa registrada")
                            .font(.custom("SF Pro", size: 17, relativeTo: .headline))
                            .fontWeight(.medium)
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
                // Mostrar lista de recompensas
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
                            
                            // ✅ CORREÇÃO: Usar as recompensas do grupo diretamente
                            ForEach(group.rewards.indices, id: \.self) { index in
                                let reward = group.rewards[index]
                                
                                // Encontrar o índice no array principal para binding
                                if let mainIndex = viewModel.rewards.firstIndex(where: {
                                    $0.rewardID == reward.rewardID &&
                                    $0.dateCollected == reward.dateCollected
                                }) {
                                    GenitorRewardsRowView(reward: $viewModel.rewards[mainIndex])
                                        .onTapGesture {
                                            saveRewardUpdate(reward)
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
    }
    
    private func loadRewards() {
        guard let kidID = viewModel.firstKid?.id?.recordName else {
            // Se não há criança, limpar rewards
            viewModel.rewards = []
            return
        }
        
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
}

#Preview {
    GenitorRewardsView()
}
