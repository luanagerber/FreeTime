//
//  GenitorRewardsRowView.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

struct GenitorRewardsRowView: View {
    @Binding var reward: CollectedReward
    var onToggle: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(action: {
                onToggle?()
            }, label: {
                Image(systemName: reward.isDelivered ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reward.isDelivered ? .green : Color("primaryColor"))
            })
            
            Text(Reward.find(by: reward.rewardID)?.name ?? "Recompensa Desconhecida")
                .font(.system(size: 17, weight: .medium))
            
            Spacer()
            
            Text("- \(Reward.find(by: reward.rewardID)?.cost ?? 0)")
            
            Image(systemName: "dollarsign.circle.fill")
        }
        .font(.custom("SF Pro", size: 17, relativeTo: .body))
        .fontWeight(.medium)
        .foregroundColor(
            reward.isDelivered ? Color("primaryColor").opacity(0.4) : Color("primaryColor")
        )
        .opacity(reward.isDelivered ? 0.5 : 1.0)
        .hSpacing(.center)
        .padding(.vertical, 8)
    }
}
