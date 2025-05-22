//
//  ParentViewModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

class GenitorViewModel: ObservableObject {

    static let shared = GenitorViewModel()
    private var cloudService: CloudService = .shared
    
    @Published var records: [ActivitiesRegister] = ActivitiesRegister.samples
    @Published var rewards: [CollectedReward] = []
    @Published var currentDate: Date = .init()
    
//    func fetchRecords() -> [Register] {
//        
//    }
}
