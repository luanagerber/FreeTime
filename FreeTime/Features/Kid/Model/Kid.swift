//
//  Child.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

struct Kid {
    let id = UUID()
    let name: String
    let parentID: UUID
    var collectedRewards = [CollectedReward]()
    
    private(set) var coins: Int
    
    init(name: String, parentID: UUID, coins: Int = 0) {
        self.name = name
        self.parentID = parentID
        self.coins = coins
    }
    
    mutating func addCoins(_ amount: Int) {
        coins += amount
    }
    
    mutating func removeCoins(_ amount: Int) {
        coins -= amount
    }
}
