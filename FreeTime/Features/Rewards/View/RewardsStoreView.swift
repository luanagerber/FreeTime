//
//  RewardsStoreView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI

struct RewardsStoreView: View {
    
    @ObservedObject var store: RewardsStore
    @EnvironmentObject var coordinator: Coordinator
    
    // Duas colunas iguais
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView(.vertical) {
                    headerSection
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.rewards) { reward in
                            rewardView(reward)
                        }
                    }
                    .padding()
                }
                
                bottomButtonsSection
            }
            
            // Loading overlay
            if store.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Processing...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
        .alert("Error", isPresented: $store.showError) {
            Button("OK", role: .cancel) {
                store.clearError()
            }
        } message: {
            Text(store.errorMessage)
        }
    }
    
    private var headerSection: some View {
        HStack {
            KidMiniProfileView(name: "Current Kid") // You might want to pass actual kid name
            CoinsView(amount: store.coins, opacity: 0.2)
        }
        .padding(.horizontal)
    }
    
    private var bottomButtonsSection: some View {
        HStack(spacing: 16) {
            collectedRewardsButton
            addCoinsButtonTest
        }
        .padding()
    }
    
    private var addCoinsButtonTest: some View {
        Button {
            store.addCoins(100)
        } label: {
            Text("Add 100 Coins")
                .foregroundStyle(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
        }
        .disabled(store.isLoading)
    }
    
    private var collectedRewardsButton: some View {
        Button {
            coordinator.push(.collectedRewards)
        } label: {
            HStack {
                Image(systemName: "gift.circle")
                Text("My Rewards")
                if !store.collectedRewards.isEmpty {
                    Text("(\(store.collectedRewards.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    func rewardView(_ reward: Reward) -> some View {
        Button {
            store.buyReward(reward)
        } label: {
            RewardCardView(
                reward: reward,
                canAfford: store.canAfford(reward)
            )
        }
        .disabled(store.isLoading || !store.canAfford(reward))
        .buttonStyle(.automatic)
    }
}

struct CoinsView: View {
    let amount: Int
    let opacity: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(.yellow)
                .imageScale(.large)
            Text("\(amount)")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color.yellow.opacity(opacity))
        .cornerRadius(10)
    }
}

struct RewardCardView: View {
    let reward: Reward
    let canAfford: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(reward.image)
                .font(.system(size: 48))
            
            Text(reward.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(canAfford ? .primary : .secondary)
            
            CoinsView(amount: reward.cost, opacity: canAfford ? 0.4 : 0.2)
            
            if !canAfford {
                Text("Not enough coins")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(canAfford ? Color(.systemGray6) : Color(.systemGray5))
        .cornerRadius(12)
        .shadow(radius: canAfford ? 2 : 0)
        .opacity(canAfford ? 1.0 : 0.6)
    }
}

struct KidMiniProfileView: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("Rewards Store")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RewardsStoreView(store: RewardsStore())
}
