//
//  KidRewardTestView.swift
//  FreeTime
//
//  Created by Maria Tereza Martins Pérez on 26/05/25.
//

import SwiftUI
import CloudKit

struct KidRewardsTestView: View {
    @StateObject private var store = RewardsStore()
    @ObservedObject private var userManager = UserManager.shared
    
    private var isValidKid: Bool {
        userManager.isChild && userManager.hasValidKid
    }
    
    private var testRewards: [Reward] {
        Array(Reward.catalog.prefix(3))
    }
    
    var body: some View {
        NavigationView {
            if isValidKid {
                mainContent
            } else {
                invalidStateView
            }
        }
        .navigationTitle("Lojinha 🛍️")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erro", isPresented: $store.showError) {
            Button("OK", role: .cancel) {
                store.clearError()
            }
        } message: {
            Text(store.errorMessage)
        }
        .onAppear {
            if isValidKid {
                store.loadKidData()
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                kidHeaderSection
                coinsSection
                rewardsSection
                historySection
                debugSection
            }
            .padding()
        }
    }
    
    private var invalidStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Usuário não configurado")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Esta view é apenas para crianças.\nConfigure o UserManager primeiro.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var kidHeaderSection: some View {
        VStack(spacing: 8) {
            Text("Olá, \(userManager.currentKidName)! 👋")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Sua lojinha de recompensas")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var coinsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🪙 Suas Moedas")
                    .font(.headline)
                Spacer()
                if store.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            
            HStack {
                CoinsView(amount: store.coins, opacity: 0.3)
                Spacer()
            }
            
            // Botões de teste (apenas para debug)
            HStack {
                Button("+ 25") {
                    store.addCoins(25)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
                
                Button("+ 50") {
                    store.addCoins(50)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
                
                Button("- 10") {
                    store.removeCoins(10)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎁 Recompensas Disponíveis")
                .font(.headline)
            
            ForEach(testRewards, id: \.id) { reward in
                HStack(spacing: 12) {
                    Text(reward.image)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(reward.cost) moedas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Comprar") {
                        store.buyReward(reward)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!store.canAfford(reward) || store.isLoading)
                }
                .padding(12)
                .background(store.canAfford(reward) ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📋 Minhas Recompensas")
                    .font(.headline)
                Spacer()
                Text("(\(store.collectedRewards.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if store.collectedRewards.isEmpty {
                Text("Nenhuma recompensa ainda.\nCompre algo na lojinha! 🛒")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(store.collectedRewards, id: \.id) { collectedReward in
                    rewardHistoryRow(collectedReward)
                }
            }
            
            Button("Atualizar Lista") {
                store.refreshCollectedRewards()
            }
            .buttonStyle(.bordered)
            .disabled(store.isLoading)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func rewardHistoryRow(_ collectedReward: CollectedReward) -> some View {
        HStack(spacing: 12) {
            if let reward = collectedReward.reward {
                Text(reward.image)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(collectedReward.dateCollected, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                
                Text("Recompensa desconhecida")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if collectedReward.isDelivered {
                    Text("Entregue ✅")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    Text("Aguardando 🕐")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(10)
        .background(collectedReward.isDelivered ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔧 Debug Info")
                .font(.headline)
            
            Text("Kid ID: \(userManager.currentKidID?.recordName ?? "None")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Banco: Compartilhado")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    KidRewardsTestView()
}
