//
//  RecordViewModel.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 07/05/25.
//

import SwiftUI

class RecordViewModel: ObservableObject {
    
    @Published var records: [Record] {
        didSet {
            // Se a variável records mudar, a função checa se deve recompensar
            rewardKid()
        }
    }
    
    @EnvironmentObject var coordinator: Coordinator
    
    init() {
        self.records = [.sample1, .sample2, .sample1, .sample2]
    }
    
    func rewardKid(){
        for record in records {
            if checkRecordIsDone(record) {
                // reward kid with coins
                coordinator.kid.addCoins(record.activity.rewardPoints)
            }
        }
    }
    
    private func checkRecordIsDone(_ record: Record) -> Bool {
        if record.recordStatus == .completed {
            true
        } else {
            false
        }
    }
    
}
