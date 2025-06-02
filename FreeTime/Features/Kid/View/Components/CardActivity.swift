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
        ZStack{
            Text(register.activity?.imageNameKid ?? "nada")
            //Image(.imageBookKid)
            Image(register.activity?.imageNameKid ?? " ")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(alignment: .bottom){
                    Rectangle()
                        .fill(.orangeKid)
                        .frame(height: 65)
                        .overlay(alignment: .center){
                            VStack(spacing: 5){
                                Text(register.activity?.name ?? "Sem atividade")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(register.date.formattedAsRoundedHour())
                                    .font(.title3)
                                
                            }
                            .foregroundColor(.fontColorKid)
                        }
                }
                .roundedBorder(.borderCardActivyKid, width: 1, cornerRadius: 20)
                .cornerRadius(20)
                .frame(width: 360, height: 210)
                
            }
        .fontDesign(.rounded)
        
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
    CardActivity(register: .sample2)
}
