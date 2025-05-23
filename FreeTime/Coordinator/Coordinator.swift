//
//  Coordinator.swift
//  Testes
//
//  Created by Pedro Larry Rodrigues Lopes on 06/09/24.
//

import SwiftUI

enum Page: Hashable {
    //setup pages
    case kidManagement
    case kidWaitingInvite
    
    // home
    case activityManagement /*View de Teste*/
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
        case .kidManagement:
            KidManagementView()
        case .kidWaitingInvite:
            KidWaitingInviteView()
        case .activityManagement:
            ActivityManagementDebugView()
        case .kidHome:
            KidHomeView()
        case .genitorHome:
            GenitorHomeView()
        case .rewardsStore:
            RewardsStoreView(store: self.rewardsStore)
        case .collectedRewards:
            CollectedRewardsView(store: self.rewardsStore)
        }
    }
}
