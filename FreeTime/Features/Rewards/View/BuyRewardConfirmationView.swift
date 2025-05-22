//
//  BuyRewardConfirmationView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 15/05/25.
//

import SwiftUI

struct BuyRewardConfirmationView: View {
    
    typealias Colors = Constants.UI.Colors
    let reward: Reward
    @EnvironmentObject var coordinator: Coordinator
    @State var showInsufficientCoinsAlert: Bool = false
    @State var showSucessAlert: Bool = false
    
    private var baseRectangle: some View {
        Rectangle()
            .foregroundStyle(.white)
            .frame(width: 540, height: 620)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius))
    }
    
    private var rewardImage: some View {
        VStack {
            Rectangle()
                .frame(width: 540)
                .frame(maxHeight: 405)
            
                .clipShape(CustomCornerShape(radius: 20, corners: [.allCorners]))
                .foregroundStyle(Colors.lightGray)
             
        }
    }
    
    private var rewardCostCapsule: some View {
        ZStack{
            HStack {
                Circle()
                    .foregroundStyle(.gray)
                    .frame(width: 35)
                Text("\(reward.cost)")
                    .foregroundStyle(.black)
                    .font(.title)
                    
            }
            .padding()
            .background {
                Capsule()
                    .padding(.vertical, 10)
                    .foregroundStyle(.gray.mix(with: .white, by: 0.8))
            }
           
        }
    }
    
    var body: some View {
        baseRectangle
            .overlay(alignment: .top) {
                VStack {
                    rewardImage
                    
                    HStack {
                        Text(reward.name)
                            .fontWeight(.semibold)
                            .font(.title)
                            .foregroundStyle(.black)
                        Spacer()
                        rewardCostCapsule
                    }
                    .padding([.top, .horizontal], 42)
                    .background()
                    
                    buyButton
                        .padding(.top,30)
                        .padding(.bottom, 30)
                        
                }
            }
    }
    
    private var buyButton: some View {
        Button {
            do {
                try coordinator.rewardsStore.collectReward(reward: reward)
                showSucessAlert = true
            } catch RewardsStoreError.notEnoughCoins{
                showInsufficientCoinsAlert = true
            } catch {
                
            }
        } label: {
            Text("Comprar recompensa")
                .foregroundStyle(.black)
                .font(.title3)
                .fontWeight(.medium)
                .padding(14)
            
                .background(Colors.lightGray)
                .clipShape(.capsule)
        }
        .alert("Sucesso na compra", isPresented: $showSucessAlert) {
            Button("OK", role: .cancel) {
                coordinator.dismissSheet()
            }
        } message: {
            VStack {
                Text("Compra feita com sucesso")
            }
        }
        .alert("Moedas insuficientes", isPresented: $showInsufficientCoinsAlert) {
            Button("OK", role: .cancel) {
                coordinator.dismissSheet()
            }
        } message: {
            Text("Você precisa de mais moedas para comprar este item.")
        }
    }
}

#Preview {
    let coordinator = Coordinator()
    ZStack {
        Color.blue.opacity(0.2)
            .ignoresSafeArea(.all)
        coordinator.build(sheet: .buyRewardConfirmation(Reward.sample))
            .environmentObject(coordinator)
    }
}

