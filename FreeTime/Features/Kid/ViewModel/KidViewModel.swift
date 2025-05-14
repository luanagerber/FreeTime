//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI

class KidViewModel: ObservableObject {
    @Published var records: [Register] = Register.samples
    
    func recordsForToday(kidId: UUID) -> [Register] {
        records
            .filter { $0.kid.id == kidId && Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    func notStartedRecords(kidId: UUID) -> [Register] {
        recordsForToday(kidId: kidId)
            .filter { $0.registerStatus == .notStarted }
    }
    
    func completedRecords(kidId: UUID) -> [Register] {
        recordsForToday(kidId: kidId)
            .filter { $0.registerStatus == .completed }
    }
}
