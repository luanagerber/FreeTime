//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

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
    
    var color: Color {
        switch self {
            //Provisionally
            case .notStarted: return .green.opacity(0.3)
            case .inProgress: return .yellow
            case .completed: return .gray.opacity(0.3)
        }
    }
    
}

enum Tag {
    case mentalExercise
    case physicalExercise
    case socialActivity
    case study
}
