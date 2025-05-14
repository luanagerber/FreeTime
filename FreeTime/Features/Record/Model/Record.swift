//
//  Record.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation
import SwiftUI

struct Record: Identifiable {
    var id: UUID
    let child: Kid
    let parent: Genitor
    let activity: ActivityCloudkit
    let date: Date
    let duration: TimeInterval
    
    // States
    var recordStatus: RecordState

    init (child: Kid, parent: Genitor,activity: ActivityCloudkit, date: Date, duration: TimeInterval, recordStatus: RecordState) {
        self.id = UUID()
        self.child = child
        self.parent = parent
        self.activity = activity
        self.date = date
        self.duration = duration
        self.recordStatus = recordStatus
    }
}

enum RecordState {
    case notStarted
    case inProgress
    case completed
    
    var color: Color {
        switch self {
            //Provisionally
            case .notStarted: return .green.opacity(0.3)
            case .inProgress: return .yellow
            case .completed: return .gray.opacity(0.3)
        }
    }
}
