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
            
//            VStack(alignment: .leading) {
                // Usar o catálogo existente de Reward
                Text(Reward.find(by: reward.rewardID)?.name ?? "Recompensa Desconhecida")
                .font(.system(size: 17, weight: .medium))
//                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
//                    .fontWeight(.medium)
                
//                Text(reward.dateCollected, style: .time)
//                    .font(.custom("SF Pro", size: 13, relativeTo: .caption))
//                    .foregroundColor(.secondary)
//            }
            
            Spacer()
            
            Text("- \(Reward.find(by: reward.rewardID)?.cost ?? 0)")
//                .font(.custom("SF Pro", size: 17, relativeTo: .body))
//                .fontWeight(.medium)
            
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

#Preview {
    @Previewable @State var record = CollectedReward.samples[0]
    
    GenitorRewardsRowView(reward: $record)
}
