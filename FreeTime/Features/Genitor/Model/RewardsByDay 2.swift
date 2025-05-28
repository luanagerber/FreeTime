//
//  RewardsByDay.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

struct RewardsByDay: Hashable, Identifiable {
    let id = UUID()
    let date: Date
    var rewards: [CollectedReward]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

