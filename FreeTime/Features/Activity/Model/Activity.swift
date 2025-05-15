//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

struct Activity: Identifiable {
    let id: Int
    let name: String
    var tags: [Tag]
    var description: String
    var necessaryMaterials: [String]
}

enum Tag {
    case mentalExercise
    case physicalExercise
    case socialActivity
    case study
}
