//
//  RewardCardView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 19/05/25.
//

import SwiftUI

struct RewardCardView: View {
    let reward: Reward
    let isCollected: Bool
    @EnvironmentObject var coordinator: Coordinator
    
    // Propriedade computada que retorna o índice do reward no collectedRewards, se existir
    var collectedRewardIndex: Int? {
           guard isCollected else { return nil }
           return coordinator.kid.collectedRewards.firstIndex(where: { $0.id == reward.id })
    }
    
    init(reward: Reward, isCollected: Bool = false) {
        self.reward = reward
        self.isCollected = isCollected
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(reward.image)
                .font(.system(size: 64))
                .scaledToFill()
            
            HStack {
                Text(reward.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Constants.UI.Colors.textCard)
                CoinsView(amount: reward.cost, opacity: 0.4)
                
            }
            .frame(maxWidth: 250)
            
            if let index = collectedRewardIndex {
                Text("Índice do reward coletado: \(index)")
            } else {
                //Text("nao coletado")
            }
            
        }
        .padding()
        .background(Constants.UI.Colors.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
        .overlay {
            
            if (isCollected) {
                ZStack {
                    Color.black.opacity(0.5)
                    sucessCheckmarkView
                        .opacity(0.4)
                }
            }
        }
    }
    
    private var sucessCheckmarkView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color.green.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
            
            Image(systemName: "checkmark")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
                
        }
    }
}
