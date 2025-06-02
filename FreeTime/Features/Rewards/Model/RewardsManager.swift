//
//  RewardsManager.swift
//  FreeTime
//
//  Created by Maria Tereza Martins Pérez on 02/06/25.
//

import CloudKit
import Foundation

struct RewardsManager {
    let pendingRewards: [Int] // IDs das recompensas pendentes
    let deliveredRewards: [Int] // IDs das recompensas entregues
    
    init(pendingRewards: [Int] = [], deliveredRewards: [Int] = []) {
        self.pendingRewards = pendingRewards
        self.deliveredRewards = deliveredRewards
    }
}
