//
//  GenitorRewardsRowView.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

struct GenitorRewardsRowView: View {
    @Binding var reward: CollectedReward

        var body: some View {
            HStack {
                // Ícone de checado ou círculo, dependendo do status 'delivered'
                
                Button(action: {
                    reward.isDelivered.toggle()
                }, label: {
                    Image(systemName: reward.isDelivered ? "checkmark.circle.fill" : "circle")
                        
                })
                
                
                Text(Reward.catalog[reward.rewardID].name) // Nome da recompensa
                
                Spacer()
                
                Text("- \(Reward.catalog[reward.rewardID].cost)")
                
                Image(systemName: "dollarsign.circle.fill")
            }
            .foregroundColor(reward.isDelivered ? .secondary : .black)
            .hSpacing(.center)
            .font(.custom("SF Pro", size: 17, relativeTo: .body))
            .fontWeight(.medium)
            .foregroundStyle(.black)
            //.foregroundColor(reward.isDelivered ? .secondary : .black)
        }
}

#Preview {
    @Previewable @State var record = CollectedReward.samples[0]
    
    GenitorRewardsRowView(reward: $record)
}
