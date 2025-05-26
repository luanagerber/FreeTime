//
//  GenitorRewardsView.swift
//  FreeTime
//
//  Created by Thales Araújo on 22/05/25.
//

import SwiftUI

struct GenitorRewardsView: View {
    var body: some View {
        VStack() {
            HeaderView()
        }
        .vSpacing(.top)
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        
        VStack(alignment: .leading) {
            
            Text("Histórico")
                .font(.custom("SF Pro", size: 34, relativeTo: .largeTitle))
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            Text("Confira as recompensas da criança e marque quando forem entregues.")
                .font(.custom("SF Pro", size: 15, relativeTo: .body))
            
            Rectangle()
                .foregroundStyle(.clear)
                .background(.backgroundHeaderCoins)
                .frame(width: 350, height: 44)
                .cornerRadius(10)
                .overlay{
                    HStack {
                        Text("Saldo da criança")
                        
                        Spacer()
                        
                        Text("25")
                        
                        Image(systemName: "dollarsign.circle.fill")
                    }
                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .fontWeight(.medium)
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
                    .padding()
                }
                
        }
        .hSpacing(.leading)
        .padding(20)
    }
}

#Preview {
    GenitorRewardsView()
}
