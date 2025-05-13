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
    
    // Duas colunas iguais
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    KidMiniProfileView(name: store.kid.name)
                    coinsView
                }
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.rewards) { reward in
                        rewardView(reward)
                    }
                }
                .padding()
            }
            
            Button {
                // Direcionar pra tela de resgatadas
            } label: {
                Text("Tela de resgatadas")
            }

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
        
    }
    
    private var coinsView: some View {
        HStack(spacing: 4) {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(.yellow)
                .imageScale(.large)
            Text("\(store.kid.coins)")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.2))
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
                .foregroundStyle(.black)
            
            Text("\(reward.cost) pontos")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
