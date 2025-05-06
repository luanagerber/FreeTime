//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation

struct Child {
    let id: Float
    // resto ...
}

struct Activity: Identifiable {
    let id = UUID()
    let name: String
    var tags: [Tag]
    var description: String
    var necessaryMaterials: [String]
    
    // States
    var activityState: ActivityState = .notStarted
    
    var startedAt: Date?
    var FinishedAt: Date?
    
    // Information that will be provided by the responsible
    var scheduledDate: Date?
    var duration: TimeInterval?

}

// Os estados inProgress e completed carregam a data de início e fim da atividade
enum ActivityState {
    case notStarted
    case inProgress //(Date)
    case completed //(Date)
}

enum Tag {
    case mentalExercise
    case physicalExercise
    case socialActivity
    case study
}
