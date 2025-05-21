//
//  SectionProfile.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import SwiftUI

struct SectionProfile: View {
    let kid: Kid
    var moedas: Double = 500
    @EnvironmentObject var coordinator: Coordinator
    let currentPage: Page
    
    var body: some View {
        
        ZStack{
            Rectangle()
                .fill(.gray)
                .cornerRadius(18)
            
            
            HStack(spacing: 20){
                Circle()
                    .frame(width: 70, height: 70)
                
                VStack(alignment: .leading, spacing: 10){
                    Text(kid.name)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    Text(String(format: "$%.2f", moedas))//Depois atualizar as moedas
                        .font(.system(size: 17, weight: .regular, design: .default))
                }
                Spacer()
                
                buttonsDestinations(title: "Atividades", destination: .kidHome)
                Divider()
                    .frame(width: 2, height: 70)
                    .background(Color.white)
                
                buttonsDestinations(title: "Lojinha", destination: .rewardsStore)
                
                
            }.frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 30)
                .foregroundColor(.white)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: 126)
    }
    
    private func buttonsDestinations(title: String, destination: Page) -> some View {
        let isCurrent = destination == currentPage
        
        return Button {
            if !isCurrent {
                coordinator.push(destination)
            }
        } label: {
            VStack {
                Rectangle()
                    .fill(isCurrent ? Color.green : Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .cornerRadius(20)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .disabled(isCurrent)
    }

}

#Preview {
    CoordinatorView()
}
