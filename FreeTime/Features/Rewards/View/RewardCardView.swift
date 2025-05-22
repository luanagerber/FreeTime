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
        ZStack(alignment: .bottom){
            baseRectangle
            overlayBar
        }
    }
    
    private var rewardCostCapsule: some View {
        ZStack{
            HStack {
                Circle()
                    .foregroundStyle(.gray.opacity(0.3))
                    .frame(width: 24)
                Text("\(reward.cost)")
                    .foregroundStyle(.black)
                    
            }
            .padding()
            .background {
                Capsule()
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
            }
           
        }
    }
    
    private var baseRectangle: some View {
        Rectangle()
            .foregroundStyle(.gray.mix(with: .white, by: 0.6))
            .frame(width: Constants.UI.Sizes.rewardCardWidth, height: Constants.UI.Sizes.rewardCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius))
    }
    
    private var overlayBar: some View {
        Rectangle()
            .frame(width: Constants.UI.Sizes.rewardCardWidth, height: Constants.UI.Sizes.rewardCardHeight/3)
            .clipShape(CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight]))
            .foregroundStyle(.gray)
            .overlay {
                HStack {
                    Text(reward.name)
                        .bold()
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    rewardCostCapsule
                }
                .padding(.horizontal)
            }
    }
}

struct CustomCornerShape: Shape {
    var radius: CGFloat // O raio do arredondamento
    var corners: UIRectCorner // Os cantos a serem arredondados

    // Esta função define o caminho da forma dentro de um retângulo específico.
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
