//
//  Reward.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

struct Reward: Identifiable, Equatable {
    
    let id: Int  // Changed to Int for stable catalog reference
    let name: String
    var cost: Int
    let image: String

    static func == (lhs: Reward, rhs: Reward) -> Bool {
        lhs.id == rhs.id
    }
}
