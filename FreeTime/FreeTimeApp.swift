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
            CoordinatorView()
//                .onAppear {
//                                    // TEMPORÁRIO: Limpa dados salvos para testar correção
//                                    UserManager.shared.reset()
//                                    print("🔄 UserManager resetado para teste")
//                                }
            
//            KidManagementDebugView() // essa é a que reset
//            ActivityManagementDebugView()
//            RewardsTestDebugView()
        }
    }
}
