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
    var kidDescription: String?
    var necessaryMaterials: [String]
    var rewardPoints: Int
    
    init(id: Int, name: String, tags: [Tag], description: String, kidDescription: String? = nil, necessaryMaterials: [String], rewardPoints: Int) {
        self.id = id
        self.name = name
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
    }
    
    // Helper method to get description for specific user type
    func getDescription(for userType: UserRole) -> String {
        switch userType {
        case .kid:
            return kidDescription ?? description
        case .genitor:
            return description
        case .undefined:
            return description
        }
    }
}
