//
//  RewardCardView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 19/05/25.
//

import SwiftUI

struct RewardCardView: View {
    
    typealias Colors = Constants.UI.Colors
    typealias Sizes = Constants.UI.Sizes
    
    @EnvironmentObject var coordinator: Coordinator
    
    let reward: Reward
    let isCollected: Bool
    
    init(reward: Reward, isCollected: Bool = false) {
        self.reward = reward
        self.isCollected = isCollected
    }
    
    var body: some View {
        ZStack(alignment: .bottom){
            baseRectangle
            overlayBar
        }
        
    }
    
     var rewardCostCapsule: some View {
        ZStack{
            HStack {
                // coin
                ZStack {
                    Circle()
                        .foregroundStyle(.coin)
                        .frame(width: 24)
                    Text("$")
                        .foregroundStyle(.text)
                        .fontWeight(.semibold)
                }
                // value
                Text("\(reward.cost)")
                    .foregroundStyle(.text)
                    .font(.title3)
                    
            }
            .padding()
            .background {
                Capsule()
                    .padding(.vertical, 6)
                    .foregroundStyle(.capsuleCoin)
            }
           
        }
    }
    
    private var baseRectangle: some View {
        Image(RewardToImageMap(reward: reward).imageName)
            .foregroundStyle(.gray.mix(with: .white, by: 0.6))
            .frame(width: Sizes.rewardCardWidth, height: Sizes.rewardCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 5, x: 4, y: 4)
           
    }
    
    private var overlayBar: some View {
        Rectangle()
            .frame(width: Sizes.rewardCardWidth, height: Sizes.rewardCardHeight/3)
            .clipShape(CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight]))
            .foregroundStyle(.cardOverlayBar)
            .overlay {
                HStack {
                    Text(reward.name)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.text)
                    
                    Spacer()
                    
                    rewardCostCapsule
                }
                .padding(.horizontal)
            }
    }
}

#Preview ("Card não coletado") {
    ZStack {
        Constants.UI.Colors.defaultBackground
            .ignoresSafeArea(.all)
        HStack {
            RewardCardView(reward: Reward.sample)
            RewardCardView(reward: Reward.sample)
        }
    }
}
