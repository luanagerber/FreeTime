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
                
                ConfirmButton(title: "Concluir Atividade", showPopUp: $showPopUp)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .topTrailing){
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.trailing, 16)
                .padding(.top, 13)
            }
            
            if showPopUp {
                PopUp(showPopUp: $showPopUp)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showPopUp = false
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
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
                .fill(.gray.opacity(0.4))
                .cornerRadius(10)
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                
                Spacer()
                
                Rectangle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 98, height: 42)
                    .overlay {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(.gray.opacity(0.4))
                                .frame(width: 24, height: 24)
                            Text(coins.description)
                                .font(.system(size: 22))
                        }
                    }
                    .cornerRadius(20)
            }
            .padding(.horizontal, 42)
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
                .fill(.gray.opacity(0.2))
                .cornerRadius(16)
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .overlay {
                        Text(title)
                            .font(.system(size: 20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 42)
                    .cornerRadius(16)
                
                Text(text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .font(.system(size: 17))
                    .padding(12)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity, maxHeight: height)
        .padding(.horizontal, 42)
    }
}

struct ConfirmButton: View {
    let title: String
    @Binding var showPopUp: Bool
    
    var body: some View {
        Button {
            withAnimation {
                showPopUp = true
            }
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
