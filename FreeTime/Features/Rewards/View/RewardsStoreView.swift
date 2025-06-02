//
//  RewardsStoreView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI

struct RewardsStoreView: View {
    
    typealias Colors = Constants.UI.Colors
    @ObservedObject var store: RewardsStore
    @EnvironmentObject var coordinator: Coordinator
    @State var messageOffset: HeaderMessageStateOffset = .hidden
    @State var timerProgress = 0.0
    
    // grid with 4 columns
    let rows = Array(repeating: GridItem(.flexible(), spacing: 36), count: 2)
    
    var body: some View {
        ZStack{
            Color(.defaultBackground)
                .ignoresSafeArea(.all)
            
            VStack {
                
                ScrollView(.vertical){
                    VStack(alignment: .leading){
                        
                        header(store.headerState)
                        //.padding(.horizontal, 132)
                        rewardsGrid
                    }
                    .padding(.leading, 132)
                    
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            KidMiniProfileView(name: UserManager.shared.currentKidName.isEmpty ? "Current Kid" : UserManager.shared.currentKidName)
            CoinsView(amount: store.coins, opacity: 0.2)
        }
        .padding(.horizontal)
    }
    
    enum HeaderMessageStateOffset: CGFloat {
        case hidden = 900.0
        case shown = 0.0
    }
    
    private var rewardsGrid: some View {
        ScrollView(.horizontal){
            LazyHGrid(rows: rows, spacing: 36) {
                
                ForEach(store.rewards) { reward in
                    rewardView(reward)
                }
            }
            .scrollTargetLayout()
            .padding(.trailing, 36)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    func buildHeader(message: String? = nil, color: Color = .message) -> some View {
        HStack(alignment: .center){
            VStack(alignment: .leading, spacing: 8){
                titleText
                subtitleText
            }
            .padding(.trailing)
            .padding([.top, .bottom], 32)
            
            
            if let message = message {
                headerMessage(message: message, color: color)
                    .offset(x: messageOffset.rawValue)
                    .onAppear {
                        withAnimation(.bouncy(duration: 1.00, extraBounce: -0.5)) {
                            messageOffset = .shown
                        }
                    }
                    .task {
                        do {
                            try await Task.sleep(for: .seconds(8))
                            
                            withAnimation(.bouncy(duration: 1.00, extraBounce: -0.5)) {
                                
                                messageOffset = .hidden
                            }
                            
                            //TODO: se der tempo, ajeitar
                            try await Task.sleep(for: .seconds(1))
                            store.setHeaderNormal()
                        } catch {
                            
                        }
                    }
            }
        }
        .padding(.top, 32)
    }
    
    func headerMessage(message: String, color: Color) -> some View {
        ZStack(alignment: .leading){
            CustomCornerShape(radius: 20, corners: [.topLeft, .bottomLeft])
                .fill(color)
                .shadow(color: color == .errorMessage ? .errorMessageShadow : .messageShadow, radius: 0, x: -8, y: 8)
                .frame(maxWidth: .infinity)
                .frame(height: 75)
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.text)
                .padding()
                .padding(.leading, 20)
                .fontDesign(.rounded)
        }
    }
    
    
    @ViewBuilder
    func header(_ type: RewardsStore.HeaderType) -> some View {
        switch type {
        case .normal:
            buildHeader()
        case .withMessage(let message, let color):
            buildHeader(message: message, color: color)
        }
    }
    
    private var titleText: some View {
        Text("Lojinha de Recompensas")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .foregroundStyle(.text)
            .fontDesign(.rounded)
    }
    
    private var subtitleText: some View {
        Text(store.rewards.isEmpty ?
             "Hmm... parece que ainda não tem nenhuma recompensa para comprar. Que tal pedir pra um adulto adicionar uma recompensa pra você?" : "Clique nas recompensas que deseja ganhar!"
        )
        .font(.title2)
        .fontDesign(.rounded)
        .fontWeight(.regular)
        .foregroundStyle(.text)
    }
    
    @ViewBuilder
    func rewardView(_ reward: Reward) -> some View {
        Button {
            // reduce the
            coordinator.present(.buyRewardConfirmation(reward))
        } label: {
            RewardCardView(reward: reward)
        }
    }
}


#Preview ("loja"){
    struct PreviewWrapper: View {
        @StateObject var coordinator = Coordinator()
        let impossibleRewardTest = Reward(id: 1, name: "bola", cost: 999999, image: "Fortuna do Japão")
        
        var body: some View {
            NavigationStack(path: $coordinator.path) {
                RewardsStoreView(store: coordinator.rewardsStore)
                    .sheet(item: $coordinator.sheet) { sheet in
                        coordinator.build(sheet: sheet)
                            .presentationSizing(.fitted)
                            .presentationCornerRadius(20)
                    }
                
            }
            .environmentObject(coordinator)
            .onAppear(){
                //coordinator.present(.buyRewardConfirmation(impossibleRewardTest))
            }
        }
    }
    
    return PreviewWrapper()
}

#Preview ("Card não coletado") {
    ZStack {
        Constants.UI.Colors.defaultBackground
            .ignoresSafeArea(.all)
        RewardCardView(reward: Reward.sample)
    }
}

#Preview("Tela de confirmação - Modal") {
    
    struct PreviewWrapper: View {
        @StateObject var coordinator = Coordinator() // Use @StateObject para coordinators em Views
        
        var body: some View {
            NavigationStack(path: $coordinator.path) {
                RewardsStoreView(store: coordinator.rewardsStore)
                    .sheet(item: $coordinator.sheet) { sheet in
                        coordinator.build(sheet: sheet)
                            .presentationSizing(.fitted)
                            .presentationCornerRadius(20)
                    }
                
            }
            .environmentObject(coordinator)
            .onAppear(){
                coordinator.present(.buyRewardConfirmation(Reward.catalog[0]))
            }
        }
    }
    return PreviewWrapper()
}


