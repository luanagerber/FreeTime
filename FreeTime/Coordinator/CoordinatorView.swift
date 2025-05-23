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
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(page: initialPage)
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
        }
        .environmentObject(coordinator)
        .environmentObject(invitationManager)
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
        switch invitationManager.currentStatus {
        case .accepted, .sent:
            return .genitorHome
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
