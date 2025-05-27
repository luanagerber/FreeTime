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
            
            //            Image(.navigationBar)
            //                .resizable()
            
            VStack(spacing: 24){
                Header(title: register.activity?.name ?? "Sem atividade",
                       coins: register.activity?.rewardPoints ?? 0)
                
                
                InfoBox(title: "Descrição",
                        text: register.activity?.description ?? "Essa atividade não possui descrição.",
                        height: 208,
                        topPadding: 15)
                
                
                InfoBox(title: "Horário",
                        text: register.date.timeRange(duration: register.duration),
                        height: 92,
                        topPadding: 0)
                
                
                ConfirmButton(title: "Concluir Atividade", showPopUp: $showPopUp, dismiss: {
                    dismiss()
                    kidViewModel.concludedActivity(register: register)
                })
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .topTrailing){
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.black)
                }
                .padding(.trailing, 14)
                .padding(.top, 13)
            }
            
            
            
            
//            if showPopUp {
//                PopUp(showPopUp: $showPopUp)
//                    .transition(.move(edge: .top).combined(with: .opacity))
//                    .zIndex(1)
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                            withAnimation {
//                                showPopUp = false
//                            }
//                        }
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//            }
        }
       
        .foregroundColor(.fontColorKid)
        .fontDesign(.rounded)
        .ignoresSafeArea()
        .animation(.easeInOut, value: showPopUp)
    }
}

struct Header: View {
    let title: String
    let coins: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.orangeKid)
                .cornerRadius(16)
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
        .frame(maxWidth: .infinity, maxHeight: 132)
    }
}

struct InfoBox: View {
    let title: String
    let text: String
    let height: CGFloat
    let topPadding: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.backgroundRoundedRectangleCoins)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
            //.frame(height: height)
            
            VStack(spacing: 12) {
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
                    .frame(width: 450)
                    .padding(12)
                
                
            }
            .frame(height: height, alignment: .top)
            
        }
        .padding(.horizontal, 32)
        
        .padding(.top, topPadding)
        
    }
    
}

struct ConfirmButton: View {
    let title: String
    @Binding var showPopUp: Bool
    let dismiss: () -> Void
    
    var body: some View {
                Button {
                    withAnimation {
                        showPopUp = true
                    }
                    dismiss()
                } label: {
                    Rectangle()
                        .fill(.gray.opacity(0.4))
                        .frame(width: 228, height: 48)
                        .cornerRadius(24)
                        .overlay {
                            Text(title)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                        }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 22)
            }
        
}


#Preview {
    DetailView(kidViewModel: KidViewModel(), register: ActivitiesRegister.sample1)
}
