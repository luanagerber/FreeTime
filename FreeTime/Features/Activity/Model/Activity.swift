//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation

struct Activity: Identifiable {
    let id = UUID()
    let name: String
    var tags: [Tag]
    var description: String
    var necessaryMaterials: [String]
    
    // States
    var activityState: ActivityState = .notStarted
}

enum ActivityState {
    case notStarted
    case inProgress
    case completed
}

enum Tag {
    case mentalExercise
    case physicalExercise
    case socialActivity
    case study
}
