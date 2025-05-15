//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI

class KidViewModel: ObservableObject {
    
    private var cloudService: CloudService = .shared

    @Published var records: [Register] = Register.samples
    
    func recordsForToday(kidId: UUID) -> [Register] {
        records
            .filter { $0.kid.id == kidId && Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            .sorted { $0.date < $1.date }
    }
    
    func notStartedRegister(kidId: UUID) -> [Register] {
        registerForToday(kidId: kidId)
            .filter { $0.registerStatus == .notStarted }
    }
    
    func completedRegister(kidId: UUID) -> [Register] {
        registerForToday(kidId: kidId)
            .filter { $0.registerStatus == .completed }
    }
    
    func concludedActivity(register: Register) {
        if let index = self.register.firstIndex(where: { $0.id == register.id }) {
            self.register[index].registerStatus = .completed
        }
    }

}
