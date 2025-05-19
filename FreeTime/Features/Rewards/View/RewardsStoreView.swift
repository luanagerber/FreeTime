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
    
    // grid with 4 columns
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        ZStack {
            Constants.UI.Colors.defaultBackground
                .ignoresSafeArea(.all)
            ScrollView(.vertical){
                VStack(alignment: .leading){
                    titleText
                    
                    subtitleText
                    
                    kidStatus
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        
                        ForEach(store.rewards) { reward in
                            rewardView(reward)
                                .padding()
                        }
                        
                        ForEach(store.kid.collectedRewards) { collectedReward in
                            rewardView(collectedReward.reward, isCollected: true)
                                .padding()
                        }
                    }
                }
                .padding(64)
                HStack {
                    addCoinsButtonTest
                }
            }
        }
    }
    
    private var kidStatus: some View {
        HStack {
            KidMiniProfileView(name: store.kid.name)
            CoinsView(amount: store.kid.coins, opacity: 0.2)
                .padding(5)
        }
    }
    
    private var titleText: some View {
        Text("Loja de recompensas")
            .font(.title)
            .bold()
            .foregroundStyle(Constants.UI.Colors.titleText)
    }
    
    private var subtitleText: some View {
        Text("Clique na recompensa que deseja adquirir")
            .font(.title2)
            .foregroundColor(Constants.UI.Colors.subtitleText)
    }
    
    private var addCoinsButtonTest: some View {
        Button {
            store.kid.addCoins(100000)
        } label: {
            HStack {
                Text("Cheat de 100 000 moedas")
                Image(systemName: "plus.circle.fill")
            }
            .foregroundStyle(.white)
            .padding()
            .background(Color.yellow.opacity(0.7))
            .bold()
            .clipShape(.capsule)
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
            coordinator.present(.buyRewardConfirmation(reward))
        } label: {
            RewardCardView(reward: reward)
        }
        .buttonStyle(.automatic)
        
        
    }
    
    func rewardView(_ reward: Reward, isCollected: Bool = false) -> some View {
        Button {
            coordinator.present(.buyRewardConfirmation(reward))
        } label: {
            RewardCardView(reward: reward, isCollected: isCollected)
        }
        .buttonStyle(.automatic)
        .disabled(isCollected)
        
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
                .foregroundColor(.white)
        }
        .padding(2)
        .background(Color.yellow.opacity(opacity))
        .cornerRadius(10)
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
        .environmentObject(Coordinator())
}

#Preview ("Card não coletado") {
    ZStack {
        Constants.UI.Colors.defaultBackground
            .ignoresSafeArea(.all)
        RewardCardView(reward: Reward.sample)
    }
}

#Preview ("Card coletado") {
    ZStack {
        Constants.UI.Colors.defaultBackground
            .ignoresSafeArea(.all)
        RewardCardView(reward: Reward.sample, isCollected: true)
    }
}


