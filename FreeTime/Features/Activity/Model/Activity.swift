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
    let imageNameGenitor: String
    let imageNameKid: String
    var tags: [Tag]
    var description: String
    var kidDescription: String?
    var necessaryMaterials: [String]
    var rewardPoints: Int
    
    init (id: Int, name: String, imageNameGenitor: String, imageNameKid: String, tags: [Tag], description: String, kidDescription: String? = nil, necessaryMaterials: [String], rewardPoints: Int) {
        self.id = id
        self.name = name
        self.imageNameGenitor = imageNameGenitor
        self.imageNameKid = imageNameKid
        self.tags = tags
        self.description = description
        self.kidDescription = kidDescription
        self.necessaryMaterials = necessaryMaterials
        self.rewardPoints = rewardPoints
    }
    
    enum Tag {
        case mentalExercise
        case physicalExercise
        case socialActivity
        case study
        case creativity
    }
}
