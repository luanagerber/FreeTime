//
//  CoordinatorView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 14/05/25.
//

import SwiftUI

struct CoordinatorView: View {
    
    @StateObject var coordinator = Coordinator()
    @StateObject private var invitationManager = InvitationStatusManager.shared
    @StateObject private var launchManager = FirstLaunchManager.shared

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(page: initialPage)
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
        }
        .environmentObject(coordinator)
        .environmentObject(invitationManager)
        .environmentObject(launchManager)
    }
    
    private var initialPage: Page {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return padInitialPage
        case .phone:
            return phoneInitialPage
        default:
            return .kidWaitingInvite
        }
    }
    
    private var phoneInitialPage: Page {
        // Se for o primeiro acesso, sempre mostra KidManagement
        if !launchManager.hasCompletedInitialSetup {
            return .kidManagement
        }
        
        // Para acessos subsequentes, navega baseado no status
        switch invitationManager.currentStatus {
        case .accepted, .sent:
            return .genitorHome
//            return .rewardsStoreDebug
        case .pending:
            return .kidManagement
        }
    }
    
    private var padInitialPage: Page {
        switch invitationManager.currentStatus {
        case .accepted:
            return .kidHome
        case .pending, .sent:
            return .kidWaitingInvite
        }
    }
    
}
