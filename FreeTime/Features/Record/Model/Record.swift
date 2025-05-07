//
//  Record.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

struct Record {
    let child: Kid
    let parent: Parent
    let activity: Activity
    let date: Date
    let duration: TimeInterval
    
    init (child: Kid, parent: Parent,activity: Activity, date: Date, duration: TimeInterval) {
        self.child = child
        self.parent = parent
        self.activity = activity
        self.date = date
        self.duration = duration
    }
}
