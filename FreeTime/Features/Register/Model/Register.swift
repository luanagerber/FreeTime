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
    let activity: Activity
    let date: Date
    let duration: TimeInterval
    
    // States
    var registerStatus: RegisterStatus

    init (kid: Kid, genitor: Genitor,activity: Activity, date: Date, duration: TimeInterval, registerStatus: RegisterStatus) {
        self.id = UUID()
        self.kid = kid
        self.genitor = genitor
        self.activity = activity
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
    }
}

//enum RegisterStatus {
//    case notStarted
//    case inProgress
//    case completed
//    
//    var color: Color {
//        switch self {
//            //Provisionally
//            case .notStarted: return .green.opacity(0.3)
//            case .inProgress: return .yellow
//            case .completed: return .gray.opacity(0.3)
//        }
//    }
//}

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
