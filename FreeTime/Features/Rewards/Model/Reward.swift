//
//  Reward.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

struct Reward: Identifiable {
    
    // definition
    let id = UUID()
    let name: String
    var cost: Int
    let image: String

}
