//
//  FreeTimeApp.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

@main
struct FreeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                    ChildView()
            case.phone:
                    ParentView()
            default:
                EmptyView()
            }
        }
    }
}
