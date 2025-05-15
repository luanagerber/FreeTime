//
//  Record.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation
import SwiftUI

struct Register: Identifiable {
    var id: UUID
    let kid: Kid
    let genitor: Genitor
    let activityID: UUID // Store just the UUID reference to the Activity
    let date: Date
    let duration: TimeInterval
    
    // States
    var registerStatus: RegisterStatus

    init (kid: Kid, genitor: Genitor, activityID: UUID, date: Date, duration: TimeInterval, registerStatus: RegisterStatus) {
        self.id = UUID()
        self.kid = kid
        self.genitor = genitor
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
    }
    
    // Computed property to fetch the activity from the catalog
    var activity: Activity? {
        Activity.catalog.first { $0.id == activityID }
    }
}

// @ Alterado para integrar o CloudKit
enum RegisterStatus: Int {
    case notStarted = 0
    case inProgress = 1
    case completed = 2
    
    var color: Color {
        switch self {
            case .notStarted: return .green.opacity(0.3)
            case .inProgress: return .yellow
            case .completed: return .gray.opacity(0.3)
        }
    }
}
