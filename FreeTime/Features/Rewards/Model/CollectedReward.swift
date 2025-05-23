//
//  CollectedReward.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

struct CollectedReward: Identifiable {
    
    let id = UUID()
    let reward: Reward
    let date: Date
    
}
