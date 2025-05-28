//
//  ActivityModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//
import Foundation
import SwiftUI

struct Activity: Identifiable, Hashable {
    let id: Int
    let name: String
    var tags: [Tag]
    var description: String
    var necessaryMaterials: [String]
    var rewardPoints: Int
    
    init (id: Int, name: String, tags: [Tag], description: String, necessaryMaterials: [String], rewardPoints: Int) {
        self.id = id
        self.name = name
        self.tags = tags
        self.description = description
        self.necessaryMaterials = necessaryMaterials
        self.rewardPoints = rewardPoints
    }
    
    enum Tag {
        case mentalExercise
        case physicalExercise
        case socialActivity
        case study
    }
}
