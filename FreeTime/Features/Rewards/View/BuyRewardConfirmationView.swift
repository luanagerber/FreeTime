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
    let store: RewardsStore
    
    var body: some View {
        
        baseRectangle
            .overlay(alignment: .top) {
                VStack {
                    rewardImage
                    
                    HStack {
                        Text(reward.name)
                            .font(.title)
                            .fontDesign(.rounded)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                        Spacer()
                        rewardCostCapsule
                    }
                    .padding(.horizontal, 32)
                    
                    buyButton
                        .padding(.top,67)
                        .padding(.bottom, 30)
                        
                }
            }
    }
    
    private var baseRectangle: some View {
        Rectangle()
            .foregroundStyle(.white)
            .frame(width: 540, height: 620)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius))
           
    }
    
    private var exitButton: some View {
        Button {
            coordinator.dismissSheet()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20))
                .padding(20)
                .padding(.trailing, 5)
                .foregroundStyle(.black.opacity(0.8))
        }
    }
    
    private var rewardImage: some View {
        //VStack {
            Image(RewardToImageMap(reward: reward).imageName + "Sheet")
                .resizable()
                //.aspectRatio(contentMode: .fit)
                //.frame(width: 540)
                //.frame(maxWidth: .infinity)
                .frame(width: 560)
                .frame(maxHeight: 405)
                
            
                .clipShape(CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .foregroundStyle(Colors.lightGray)
                .ignoresSafeArea(.all)
                .overlay(alignment: .topTrailing){
                    exitButton
                }
             
        //}
    }
    
    private var rewardCostCapsule: some View {
        ZStack{
            HStack {
                ZStack{
                    Circle()
                        .foregroundStyle(.coin)
                        .frame(width: 35)
                    Text("$")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .fontDesign(.rounded)
                }
                Text("\(reward.cost)")
                    .foregroundStyle(.text)
                    .font(.title2)
                    .fontWeight(.regular)
                    .fontDesign(.rounded)
                    
            }
            .padding()
            .background {
                Capsule()
                    .padding(.vertical, 10)
                    .foregroundStyle(.capsuleCoin)
            }
           
        }
    }
    
    private var buyButton: some View {
        Button {
            do {
                try coordinator.rewardsStore.collectReward(reward: reward)
                store.setHeaderMessage("Uhuul! Você acabou de conquistar uma nova recompensa!!")
                coordinator.dismissSheet()
            } catch RewardsStoreError.notEnoughCoins{
                
                store.setHeaderMessage("Ops! Você ainda não tem moedinhas suficientes para comprar essa recompensa..", color: .errorMessage)
                coordinator.dismissSheet()
            } catch {
                coordinator.dismissSheet()
            }
        } label: {
            Text("Comprar recompensa")
                .foregroundStyle(.black)
                .font(.title3)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .padding(15)
                .background(.ctaButton)
                .clipShape(.capsule)
                .shadow(color: .ctaButtonShadow, radius: 0, x: 0, y: 5)
        }
    }
}

#Preview {
    let coordinator = Coordinator()
    ZStack {
        Color.blue.opacity(0.2)
            .ignoresSafeArea(.all)
        coordinator.build(sheet: .buyRewardConfirmation(Reward.catalog[6]))
            .environmentObject(coordinator)
    }
}

