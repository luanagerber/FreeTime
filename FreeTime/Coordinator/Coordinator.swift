//
//  Coordinator.swift
//  Testes
//
//  Created by Pedro Larry Rodrigues Lopes on 06/09/24.
//

import SwiftUI

enum Page: Hashable {
    //invite
    case kidWaitingInvite
    
    // home
    case genitorHome
    case kidHome
    
    // store
    case rewardsStore
    case collectedRewards
}

class Coordinator: ObservableObject {
    
    @Published var path = NavigationPath()
    
    let rewardsStore = RewardsStore()
    var kid = Kid.sample
    
    func push(_ page: Page){
        path.append(page)
    }
    
    func pop(){
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    @ViewBuilder
    func build(page: Page) -> some View {
        switch page {
            case .kidWaitingInvite:
                WaitingInvite()
            case .kidHome:
                KidHomeView()
            case .genitorHome:
                GenitorView()
            case .rewardsStore:
                RewardsStoreView(store: self.rewardsStore)
            case .collectedRewards:
                CollectedRewardsView(store: self.rewardsStore)
        }
    }
}
