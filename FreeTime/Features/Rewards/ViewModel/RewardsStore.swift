//
//  RewardsStore.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import SwiftUI
import Foundation

class RewardsStore: ObservableObject {
    // Ava
    @Published var rewards: [Reward]
    
    // collected rewards by the kid
    @Published var kid: Kid
    
    init() {
        self.rewards = RewardsStore.getRewards()
        kid = Kid.sample
    }
    
    func collectReward(reward: Reward) throws {
        // remove the kid's coins
        if kid.coins - reward.cost >= 0 {
            
            // add to the collected rewards
            let collectedReward = CollectedReward(reward: reward, date: Date())
            kid.collectedRewards.append(collectedReward)
            
            //remove from the available rewards
            if let index = rewards.firstIndex(of: reward) {
                rewards.remove(at: index)
            }
            
            kid.removeCoins(reward.cost)
        } else {
            throw RewardsStoreError.notEnoughCoins
        }
    }
    
    static func getRewards() -> [Reward] {
        return Reward.samples
    }
}

enum RewardsStoreError: Error {
    case notEnoughCoins
}
