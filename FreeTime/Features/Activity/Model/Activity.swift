//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

struct Activity: Identifiable {
    let id: UUID
    let name: String
    var tags: [Tag]
    var description: String
    var necessaryMaterials: [String]
    
    init (name: String, tags: [Tag], description: String, materials: [String]) {
        self.id = UUID()
        self.name = name
        self.tags = tags
        self.description = description
        self.necessaryMaterials = materials
    }
}

enum Tag {
    case mentalExercise
    case physicalExercise
    case socialActivity
    case study
}
