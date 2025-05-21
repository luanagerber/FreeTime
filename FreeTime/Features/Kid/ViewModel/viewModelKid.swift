//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI
import CloudKit

class viewModelKid: ObservableObject {
    
    private var cloudService: CloudService = .shared
    @Published var kid: Kid = ActivitiesRegister.kidTest

    @Published var register: [ActivitiesRegister] = ActivitiesRegister.samples
    
//    func registerForToday(kidID: String) -> [ActivitiesRegister] {
//        register
//            .filter { $0.kidID == kidID && Calendar.current.isDate($0.date, inSameDayAs: Date()) }
//            .sorted { $0.date < $1.date }
//    }
//    
//    func notStartedRegister(kidID: CKRecord.ID) -> [ActivitiesRegister] {
//        registerForToday(kidID: kidID)
//            .filter { $0.registerStatus == .notStarted }
//    }
//    
//    func completedRegister(kidID: String) -> [ActivitiesRegister] {
//        registerForToday(kidID: kidID)
//            .filter { $0.registerStatus == .completed }
//    }
//    
//    func concludedActivity(register: ActivitiesRegister) {
//        if let index = self.register.firstIndex(where: { $0.id == register.id }) {
//            self.register[index].registerStatus = .completed
//        }
//    }

}
