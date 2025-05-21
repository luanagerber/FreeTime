//
//  DetailsActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import SwiftUI

struct DetailsActivityModal: View {
    @ObservedObject var kidViewModel: KidViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var register: ActivitiesRegister
    
    var body: some View {
        VStack(spacing: 32){
            headerDetails(title: register.activity?.name ?? "Sem atividade", coins: 500)
            
            informationBox(title: "Descrição", descripition: register.activity?.description ?? "Essa atividade não possui descrição.",heightBox: 208)
            
            informationBox(title: "Horário", descripition: register.date.timeRange(duration: register.duration),heightBox: 92)
            
            Button {
                register.registerStatus = .completed
//                kidViewModel.concludedActivity(register: register)
                dismiss()
                
            } label: {
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .frame(width: 228, height: 48)
                    .cornerRadius(24)
                    .overlay {
                        Text("Concluir")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

    }
    
    private func headerDetails(title: String, coins: Int) -> some View {
        ZStack{
            Rectangle()
                .fill(.gray.opacity(0.4))
                .cornerRadius(10)
            HStack{
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                
                Rectangle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 98, height: 42)
                    .overlay{
                        HStack{
                            
                            Circle()
                                .fill(.gray.opacity(0.4))
                                .frame(width: 24, height: 24)
                            
                            Text(coins.description)
                                .font(.system(size: 22))
                        }
                    }
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 116)
        
    }
    
    private func informationBox(title: String, descripition: String, heightBox: CGFloat) -> some View {
        ZStack{
            Rectangle()
                .fill(.gray.opacity(0.2))
                .cornerRadius(16)
            
            VStack(spacing: 12){
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .overlay(alignment: .center){
                        Text(title)
                            .font(.system(size: 20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 42)
                    .cornerRadius(16)
                
                Text(descripition)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .font(.system(size: 17))
                    .font(.body)
                    .padding(.horizontal, 12)
                
            }.frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: heightBox)
        .padding(.horizontal, 42)
    }
    
}
