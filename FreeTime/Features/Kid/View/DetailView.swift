//
//  DetailsActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var kidViewModel: KidViewModel
    var register: ActivitiesRegister
    @State private var showPopUp = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 39){
                Header(title: register.activity?.name ?? "Sem atividade",
                       coins: register.activity?.rewardPoints ?? 0)
                
                VStack(spacing: 24){
                    InfoBox(title: "Descrição",
                            text: register.activity?.getDescription(for: .kid) ?? "Essa atividade não possui descrição.",
                            height: 208)
                    
                    
                    InfoBox(title: "Horário",
                            text: register.date.formattedAsHourOnly(),
                            height: 92)
                }
                
                ConfirmButton(isCompleted: $showPopUp, dismiss:{
                    dismiss()})
                
            }
            
            //Close Button
            .overlay(alignment: .topTrailing){
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.black)
                }
                .padding(.trailing, 14)
                .padding(.top, 13)
            }
        }
        .foregroundColor(.fontColorKid)
        .fontDesign(.rounded)
        .ignoresSafeArea()
    }
}

struct Header: View {
    let title: String
    let coins: Int
    
    var body: some View {
        ZStack {
            
            Rectangle()
                .fill(.orangeKid)
                .frame(height: 66)
                .frame(maxHeight: .infinity, alignment: .top)
            
            Rectangle()
                .fill(.orangeKid)
                .cornerRadius(20)
            
            HStack {
                Text(title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.leading, 8)
                
                Spacer()
                
                RoundedCorner(radius: 20)
                    .fill(.backgroundRoundedRectangleCoins)
                    .frame(width: 98, height: 42)
                    .overlay(alignment:.center){
                        HStack (spacing: 12){
                            Image(.iCoin)
                                .frame(width: 24, height: 24)
                            
                            Text(coins.description)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                    }
            }
            .padding(.horizontal, 24)
            .padding(.top, 15)
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
    }
}

struct InfoBox: View {
    let title: String
    let text: String
    let height: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.backgroundRoundedRectangleCoins)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
            
            
            VStack(spacing: 10) {
                Rectangle()
                    .fill(.backgroundHeaderYellowKid)
                    .overlay {
                        Text(title)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 42)
                    .cornerRadius(16)
                
                
                Text(text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .font(.title3)
                    .padding(.horizontal,12)
                
            }
            .frame(maxHeight: height, alignment: .top)
            
        }
        .frame(height: height, alignment: .top)
        .padding(.horizontal, 32)
        
    }
    
}

struct ConfirmButton: View {
    //@Binding var showPopUp: Bool
    @Binding var isCompleted: Bool
    let dismiss: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                isCompleted.toggle() // Alterna entre concluído e não
                //showPopUp = true
            }
            dismiss()
        } label: {
            Image(isCompleted ? .btUndor : .btConclusion)
                .frame(width: 228, height: 48)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 22)
    }
}


#Preview {
    DetailView(kidViewModel: KidViewModel(), register: ActivitiesRegister.sample1)
}
