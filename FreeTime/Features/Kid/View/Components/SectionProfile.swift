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
    
    var body: some View {
        
        ZStack{
            Rectangle()
                .fill(.gray)
                .cornerRadius(18)
                
            
            HStack{
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
                
                VStack{
                    Rectangle()
                        .frame(width: 50, height: 50)
                        .cornerRadius(20)
                        Text("Lojinha")
                        .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(.white)
                }
            }.frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 50)
        
            .foregroundColor(.white)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: 126)
        //.frame(maxWidth: .infinity, minHeight: 126,maxHeight: .infinity)
        
        
    }
}
