//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI

class KidViewModel: ObservableObject {
    @Published var records: [Record] = Record.samples
    
    func recordsForToday(kidId: UUID) -> [Record] {
        records
            .filter { $0.kid.id == kidId && Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    func notStartedRecords(kidId: UUID) -> [Record] {
        recordsForToday(kidId: kidId)
            .filter { $0.recordStatus == .notStarted }
    }
    
    func completedRecords(kidId: UUID) -> [Record] {
        recordsForToday(kidId: kidId)
            .filter { $0.recordStatus == .completed }
    }
}
