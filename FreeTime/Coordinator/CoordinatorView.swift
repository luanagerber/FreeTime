//
//  CoordinatorView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 14/05/25.
//

import SwiftUI

struct CoordinatorView: View {
    
    @StateObject var coordinator = Coordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(page: initialPage)
                .navigationDestination(for: Page.self) { page in
                    coordinator.build(page: page)
                }
        }
        .environmentObject(coordinator)
    }
    
    private var initialPage: Page {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return .kidWaitingInvite
        case .phone:
            return .kidManagement
        default:
            return .kidWaitingInvite
        }
    }
    
}
