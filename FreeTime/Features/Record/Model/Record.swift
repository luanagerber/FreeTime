//
//  Record.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

struct Record: Identifiable {
    var id: UUID
    let child: Kid
    let parent: Parent
    let activity: Activity
    let date: Date
    let duration: TimeInterval
    
    // States
    var recordStatus: RecordState

    init (child: Kid, parent: Parent,activity: Activity, date: Date, duration: TimeInterval, recordStatus: RecordState) {
        self.id = UUID()
        self.child = child
        self.parent = parent
        self.activity = activity
        self.date = date
        self.duration = duration
        self.recordStatus = .notStarted
    }
}

enum RecordState {
    case notStarted
    case inProgress
    case completed
}
