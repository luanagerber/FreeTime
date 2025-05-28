//
//  FirstLaunchManager.swift
//  FreeTime
//
//  Created by Luana Gerber on 25/05/25.
//

import SwiftUI

class FirstLaunchManager: ObservableObject {
    static let shared = FirstLaunchManager()
    
    @AppStorage("hasCompletedInitialSetup") var hasCompletedInitialSetup: Bool = false
    
    private init() {}
    
    func completeInitialSetup() {
        hasCompletedInitialSetup = true
    }
    
    func reset() {
        hasCompletedInitialSetup = false
    }
}
