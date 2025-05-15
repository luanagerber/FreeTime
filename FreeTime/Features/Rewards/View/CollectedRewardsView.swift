//
//  CollectedRewardsView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI

struct CollectedRewardsView: View {
    
    @StateObject var store: RewardsStore
    
    var body: some View {
        ScrollView(.vertical){
            collectedRewardsList
        }
    }
    
    @ViewBuilder
    private var collectedRewardsList: some View {
        ForEach(store.kid.collectedRewards, id: \.id){ collectedReward in
            CollectedRewardView(collected: collectedReward)
        }
    }
}

struct CollectedRewardView: View {
    let collected: CollectedReward
    
    var body: some View {
        HStack(spacing: 12) {
            
            Text(collected.reward.image)
                .font(.system(size: 48))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collected.reward.name)
                    .font(.headline)
                
                Text("Custo: \(collected.reward.cost) moedas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(collected.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
#Preview {
    let testStore = RewardsStore()
    try! testStore.collectReward(reward: Reward.sample)

    return CollectedRewardsView(store: testStore)
}
