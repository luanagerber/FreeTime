//
//  CardActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 07/05/25.
//

import SwiftUI

struct CardActivity: View {
    var register: ActivitiesRegister
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .frame(width: 365, height: 200)
                .overlay(
                    VStack(spacing: 0) {
                        
                        //Image of the Planned Activity
                        Image(register.activity?.imageNameKid ?? "Zoologico")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
//                        Rectangle()
//                            .fill(.gray.opacity(0.1))
                        
                        Rectangle()
                            .fill(.orangeKid)
                            .frame(height: 60)
                            .overlay{
                                
                                VStack(spacing: 5){
                                    
                                    Text(register.activity?.name ?? "Sem atividade")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                    
                                    Text(register.date.formattedAsRoundedHour())
                                        .font(.headline)
                                    
                                }
                                .foregroundColor(.fontColorKid)
                            }
                    }
                    
                )
                .roundedBorder(.borderCardActivyKid, width: 1, cornerRadius: 20)
        }
        
        
        .cornerRadius(20)
        
        .ignoresSafeArea()
        
    }
}

extension View {
    func roundedBorder(_ color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
}



#Preview {
    CardActivity(register: .sample1)
}
