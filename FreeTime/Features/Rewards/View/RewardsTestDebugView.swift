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
    @State private var statusMessage = "Ready to test..."
    @State private var isLoading = false
    @State private var currentKidName = "Test Kid"
    @State private var showKidSelector = false
    
    // Mock kid ID for testing (you'll need to get this from your actual kid)
    @State private var testKidID: CKRecord.ID?
    
    // Test rewards (just first two from catalog)
    private var testRewards: [Reward] {
        Array(Reward.catalog.prefix(2))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Kid Selection
                    kidSelectionSection
                    
                    // MARK: - Coins Section
                    coinsSection
                    
                    // MARK: - Available Rewards
                    availableRewardsSection
                    
                    // MARK: - Collected Rewards
                    collectedRewardsSection
                    
                    // MARK: - CloudKit Actions
                    cloudKitActionsSection
                    
                    // MARK: - Status
                    statusSection
                }
                .padding()
            }
            .navigationTitle("Rewards CloudKit Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sections
    
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
    
    private var kidSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("👶 Current Kid")
                .font(.headline)
            
            HStack {
                if testKidID != nil {
                    VStack(alignment: .leading) {
                        Text("Name: \(currentKidName)")
                        Text("ID: \(testKidID?.recordName.prefix(8) ?? "nil")...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Load Data") {
                        loadDataForKid()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                } else {
                    Text("No kid ID set - need to create or fetch a kid first")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Create Test Kid") {
                        createTestKid()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
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
                Button("Add 50 Coins") {
                    testAddCoins(50)
                }
                .buttonStyle(.bordered)
                .disabled(testKidID == nil || isLoading)
                
                Button("Add 100 Coins") {
                    testAddCoins(100)
                }
                .buttonStyle(.bordered)
                .disabled(testKidID == nil || isLoading)
                
                Button("Remove 25 Coins") {
                    testRemoveCoins(25)
                }
                .buttonStyle(.bordered)
                .disabled(testKidID == nil || isLoading)
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
            
            ForEach(testRewards, id: \.id) { reward in
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
                        testCollectReward(reward)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.coins < reward.cost || isLoading || testKidID == nil)
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
                ForEach(store.collectedRewards, id: \.id) { collectedReward in
                    HStack(spacing: 12) {
                        Text(collectedReward.reward.image)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collectedReward.reward.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(collectedReward.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            testRemoveCollectedReward(collectedReward.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .disabled(isLoading || testKidID == nil)
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
    
    private var cloudKitActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("☁️ CloudKit Actions")
                .font(.headline)
            
            VStack(spacing: 8) {
                Button("Refresh from CloudKit") {
                    loadDataForKid()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || testKidID == nil)
                
                HStack {
                    Button("Sync Coins Only") {
                        syncCoinsOnly()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || testKidID == nil)
                    
                    Button("Sync Rewards Only") {
                        syncRewardsOnly()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || testKidID == nil)
                }
                
                Button("Sync All Data") {
                    syncAllData()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || testKidID == nil)
            }
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
                if isLoading || store.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Test Functions
    
    private func createTestKid() {
        isLoading = true
        statusMessage = "Creating test kid..."
        
        let kid = Kid(name: currentKidName, coins: 100) // Start with 100 coins for testing
        
        CloudService.shared.saveKid(kid) { result in
            isLoading = false
            switch result {
            case .success(let savedKid):
                testKidID = savedKid.id
                statusMessage = "✅ Test kid created successfully"
                loadDataForKid()
            case .failure(let error):
                statusMessage = "❌ Failed to create test kid: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadDataForKid() {
        guard let kidID = testKidID else {
            statusMessage = "No kid ID available"
            return
        }
        
        isLoading = true
        statusMessage = "Loading data for kid..."
        
        store.loadDataForKid(kidID) { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Data loaded successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to load data: \(error.localizedDescription)"
            }
        }
    }
    
    private func testAddCoins(_ amount: Int) {
        isLoading = true
        statusMessage = "Adding \(amount) coins..."
        
        store.addCoinsAndSync(amount) { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Added \(amount) coins successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to add coins: \(error.localizedDescription)"
            }
        }
    }
    
    private func testRemoveCoins(_ amount: Int) {
        isLoading = true
        statusMessage = "Removing \(amount) coins..."
        
        store.removeCoinsAndSync(amount) { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Removed \(amount) coins successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to remove coins: \(error.localizedDescription)"
            }
        }
    }
    
    private func testCollectReward(_ reward: Reward) {
        isLoading = true
        statusMessage = "Collecting reward: \(reward.name)..."
        
        store.collectRewardAndSync(reward: reward) { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Collected '\(reward.name)' successfully"
            case .failure(let error):
                    statusMessage = "❌ Failed to collect reward: \(error.localizedDescription)"
            }
        }
    }
    
    private func testRemoveCollectedReward(_ rewardID: UUID) {
        isLoading = true
        statusMessage = "Removing collected reward..."
        
        store.removeCollectedRewardAndSync(by: rewardID) { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Removed collected reward successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to remove reward: \(error.localizedDescription)"
            }
        }
    }
    
    private func syncCoinsOnly() {
        isLoading = true
        statusMessage = "Syncing coins to CloudKit..."
        
        store.syncCoinsToCloudKit { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Coins synced successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to sync coins: \(error.localizedDescription)"
            }
        }
    }
    
    private func syncRewardsOnly() {
        isLoading = true
        statusMessage = "Syncing collected rewards to CloudKit..."
        
        store.syncCollectedRewardsToCloudKit { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ Collected rewards synced successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to sync rewards: \(error.localizedDescription)"
            }
        }
    }
    
    private func syncAllData() {
        isLoading = true
        statusMessage = "Syncing all data to CloudKit..."
        
        store.syncAllToCloudKit { result in
            isLoading = false
            switch result {
            case .success:
                statusMessage = "✅ All data synced successfully"
            case .failure(let error):
                statusMessage = "❌ Failed to sync data: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    RewardsTestDebugView()
}
