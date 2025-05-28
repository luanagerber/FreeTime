//
//  CollectedRewardMock.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

extension CollectedReward {
    
    static let samples: [CollectedReward] = [
        CollectedReward(kid: Kid.sample,
                        rewardID: 0,
                        dateCollected: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 1,
                        dateCollected: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 2,
                        dateCollected: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 0,
                        dateCollected: Date.init(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 1,
                        dateCollected: Date.init(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 2,
                        dateCollected:  Date.init(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 0,
                        dateCollected: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 1,
                        dateCollected: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                        isDelivered: false
                       ),
        CollectedReward(kid: Kid.sample,
                        rewardID: 2,
                        dateCollected: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                        isDelivered: false
                       )
    ]
    
}
