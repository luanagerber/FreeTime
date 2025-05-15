//
//  RewardsStoreView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI

struct RewardsStoreView: View {
    
    @ObservedObject var store: RewardsStore
    @State var showInsufficientCoinsAlert: Bool = false
    @EnvironmentObject var coordinator: Coordinator
    
    // Duas colunas iguais
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            //Color.white.ignoresSafeArea(.all)
            VStack {
                ScrollView(.vertical){
                    HStack {
                        KidMiniProfileView(name: store.kid.name)
                        CoinsView(amount: store.kid.coins, opacity: 0.2)
                    }
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.rewards) { reward in
                            rewardView(reward)
                        }
                    }
                    .padding()
                }
                HStack {
                    collectedRewards
                    addCoinsButtonTest
                }
            }
        }
    }
    
    private var addCoinsButtonTest: some View {
        Button {
            store.kid.addCoins(100000)
        } label: {
            
            Text("Tela de resgatadas")
                .foregroundStyle(.white)
                .background(Color.yellow)
        }
    }
    private var collectedRewards: some View {
        Button {
            coordinator.push(.collectedRewards)
        } label: {
            Text("Tela de resgatadas")
        }
    }
    
    func rewardView(_ reward: Reward) -> some View {
        Button {
            do {
                try store.collectReward(reward: reward)
            } catch {
                showInsufficientCoinsAlert = true
            }
        } label: {
            RewardCardView(reward: reward)
        }
        .alert("Moedas insuficientes", isPresented: $showInsufficientCoinsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Você precisa de mais moedas para comprar este item.")
        }
        .buttonStyle(.automatic)
        
    }
}

struct CoinsView : View {
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
        .padding(2)
        .background(Color.yellow.opacity(opacity))
        .cornerRadius(10)
    }
}

struct RewardCardView: View {
    let reward: Reward
    
    var body: some View {
        VStack(spacing: 8) {
            Text(reward.image)
                .font(.system(size: 48))
            
            Text(reward.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            CoinsView(amount: reward.cost, opacity: 0.4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 2)
        
    }
}

struct KidMiniProfileView: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RewardsStoreView(store: .init())
}
