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
        NavigationView {
            ScrollView(.vertical) {
                if store.isLoading {
                    ProgressView("Loading collected rewards...")
                        .padding()
                } else if store.collectedRewards.isEmpty {
                    emptyStateView
                } else {
                    collectedRewardsList
                }
            }
            .navigationTitle("Collected Rewards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        store.refreshCollectedRewards()
                    }
                    .disabled(store.isLoading)
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
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Rewards Collected Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start collecting rewards by purchasing them from the store!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private var collectedRewardsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(store.collectedRewards, id: \.id) { collectedReward in
                CollectedRewardView(
                    collected: collectedReward,
                    onDelete: {
                        store.deleteCollectedReward(collectedReward)
                    }
                )
            }
        }
        .padding()
    }
}

struct CollectedRewardView: View {
    let collected: CollectedReward
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Reward image
            if let reward = collected.reward {
                Text(reward.image)
                    .font(.system(size: 48))
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Reward name
                if let reward = collected.reward {
                    Text(reward.name)
                        .font(.headline)
                    
                    Text("Cost: \(reward.cost) coins")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unknown Reward (ID: \(collected.rewardID))")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Reward not found in catalog")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(collected.dateCollected, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Delivery status
                if collected.isDelivered {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Delivered")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "clock.circle")
                            .foregroundColor(.orange)
                        Text("Pending delivery")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let testStore = RewardsStore()
    
    // Create some test CloudKit CollectedRewards
    let reward1 = CollectedReward(kidID: "test", rewardID: 0, dateCollected: Date(), isDelivered: false)
    let reward2 = CollectedReward(kidID: "test", rewardID: 1, dateCollected: Date().addingTimeInterval(-86400), isDelivered: true)
    
    testStore.collectedRewards = [reward1, reward2]

    return CollectedRewardsView(store: testStore)
}
