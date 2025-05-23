//
//  FreeTimeApp.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

@main
struct FreeTimeApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
//            CoordinatorView()
//            KidManagementDebugView()
//            ActivityManagementDebugView()
            RewardsTestDebugView()
        }
    }
}
