//
//  RewardsTestDebugView.swift
//  FreeTime
//
//  Created by Luana Gerber on 23/05/25.
//

import SwiftUI
import CloudKit

struct RewardsTestDebugView: View {
    @StateObject private var store = RewardsStore()
    @ObservedObject private var userManager = UserManager.shared

    private var currentKidName: String {
        userManager.currentKidName.isEmpty ? "No Kid" : userManager.currentKidName
    }

    private var testRewards: [Reward] {
        Array(Reward.catalog.prefix(2))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    kidInfoSection
                    coinsSection
                    availableRewardsSection
                    collectedRewardsSection
                    fatherOperationsSection
                    cloudKitActionsSection
                    statusSection
                }
                .padding()
            }
            .navigationTitle("Rewards CloudKit Test")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $store.showError) {
                Button("OK", role: .cancel) {
                    store.clearError()
                }
            } message: {
                Text(store.errorMessage)
            }
            .onAppear {
                if let kidID = userManager.currentKidID, userManager.hasValidKid {
                    store.loadKidData()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack {
            Text("🧪 CloudKit Test & Debug")
                .font(.title2)
                .fontWeight(.bold)
            Text("Test rewards store CloudKit integration")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var kidInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("👶 Current Kid")
                .font(.headline)
            VStack(alignment: .leading) {
                Text("Name: \(currentKidName)")
                Text("Coins: \(store.coins)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var coinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🪙 Coins")
                .font(.headline)
            HStack {
                CoinsView(amount: store.coins, opacity: 0.3)
                Spacer()
            }
            HStack {
                Button("Add 50") {
                    store.addCoins(50)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
                Button("Add 100") {
                    store.addCoins(100)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
                Button("Remove 25") {
                    store.removeCoins(25)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }

    private var availableRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎁 Available Rewards")
                .font(.headline)
            ForEach(testRewards, id: \ .id) { reward in
                HStack(spacing: 12) {
                    Text(reward.image)
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(reward.cost) coins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Buy") {
                        do {
                            try store.buyReward(reward)
                        } catch {
                            print("error: \(error)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!store.canAfford(reward) || store.isLoading)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }

    private var collectedRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆 Collected Rewards")
                    .font(.headline)
                Spacer()
                Text("(\(store.collectedRewards.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if store.collectedRewards.isEmpty {
                Text("No rewards collected yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(store.collectedRewards, id: \ .id) { collectedReward in
                    HStack(spacing: 12) {
                        if let reward = collectedReward.reward {
                            Text(reward.image)
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reward.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(collectedReward.dateCollected, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if collectedReward.isDelivered {
                                    Text("✅ Delivered")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                } else {
                                    Text("⏳ Pending")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unknown Reward")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                Text("ID: \(collectedReward.rewardID)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("Remove") {
                            store.deleteCollectedReward(collectedReward)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .disabled(store.isLoading)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }

    private var fatherOperationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("👨‍👧‍👦 Father Operations")
                .font(.headline)
            HStack {
                Text("Pending: \(store.getPendingRewards().count)")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Text("Delivered: \(store.getDeliveredRewards().count)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            if let firstPending = store.getPendingRewards().first {
                Button("Mark '\(firstPending.reward?.name ?? "Unknown")' as Delivered") {
                    store.markRewardAsDelivered(firstPending)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
            } else {
                Text("No pending rewards to deliver")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    private var cloudKitActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("☁️ CloudKit Actions")
                .font(.headline)
            Button("Refresh Collected Rewards") {
                store.refreshCollectedRewards()
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isLoading)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📋 Status")
                .font(.headline)
            HStack {
                if store.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(store.isLoading ? "Loading..." : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    RewardsTestDebugView()
}
