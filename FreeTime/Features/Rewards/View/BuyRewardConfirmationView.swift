//
//  BuyRewardConfirmationView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 15/05/25.
//

import SwiftUI

struct BuyRewardConfirmationView: View {
    let reward: Reward
    @EnvironmentObject var coordinator: Coordinator
    
    
    @State var showInsufficientCoinsAlert: Bool = false
    @State var showSucessAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(reward.image)
                .font(.system(size: 128))
                .scaledToFill()
            
            HStack {
                Text(reward.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Constants.UI.Colors.textCard)
                CoinsView(amount: reward.cost, opacity: 0.4)
                
            }
            buyButton
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
            Text("Comprar")
                .foregroundStyle(Constants.UI.Colors.textCard)
                .bold()
                .padding()
            
                .background(Color.yellow)
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
        Constants.UI.Colors.defaultBackground
            .ignoresSafeArea(.all)
        coordinator.build(sheet: .buyRewardConfirmation(Reward.sample))
            .environmentObject(coordinator)
    }
}

