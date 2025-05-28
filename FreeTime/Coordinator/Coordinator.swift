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
    case rewardsStoreDebug /*View de Teste*/
}

enum Sheet: Identifiable {
    case buyRewardConfirmation(Reward)
    
    var id: String {
        switch self {
        case .buyRewardConfirmation(let reward):
            return "buyRewardConfirmation_\(reward.id)"
        }
    }
}

class Coordinator: ObservableObject {
    
    @Published var path = NavigationPath()
    @Published var sheet: Sheet?
    
    let rewardsStore = RewardsStore()
    var kid = Kid.sample
    
    func push(_ page: Page){
        path.append(page)
    }
    
    func present(_ sheet: Sheet){
        self.sheet = sheet
    }
    
    func pop(){
        path.removeLast()
    }
    
    func dismissSheet() {
        sheet = nil
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    @ViewBuilder
    func build(page: Page) -> some View {
        switch page {
        case .kidManagement:
            KidManagementView()
                .navigationBarBackButtonHidden(true)
        case .kidWaitingInvite:
            KidWaitingInviteView()
                .navigationBarBackButtonHidden(true)
        case .activityManagement:
            ActivityManagementDebugView()
        case .kidHome:
            KidHomeView()
                .navigationBarBackButtonHidden(true)
        case .genitorHome:
            GenitorCalendarView()
                .navigationBarBackButtonHidden(true)
        case .rewardsStore:
            RewardsStoreView(store: self.rewardsStore)
        case .collectedRewards:
            CollectedRewardsView(store: self.rewardsStore)
        case .rewardsStoreDebug:
            RewardsTestDebugView()
        }
    }
    
    @ViewBuilder
    func build(sheet: Sheet) -> some View {
        switch sheet {
        case .buyRewardConfirmation(let reward):
            BuyRewardConfirmationView(reward: reward, store: self.rewardsStore)
        }
    }
}
