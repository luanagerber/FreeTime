//
//  RecordMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

extension ActivitiesRegister {
    static let kidTest = Kid.sample
    
    static let samples: [ActivitiesRegister] = [
        ActivitiesRegister(
            kid: kidTest,
            activityID: Activity.catalog[0].id,
            date: Date(), // agora
            duration: 3600, // 1 hora
            registerStatus: .notStarted
        ),
        ActivitiesRegister(
            kid: kidTest,
            activityID: Activity.catalog[1].id,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), //ontem
            duration: 5400, // 1h30min
            registerStatus: .notStarted
        ),
        ActivitiesRegister(
            kid: kidTest,
            activityID: Activity.catalog[1].id,
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), //amanhã
            duration: 5400, // 1h30min
            registerStatus: .completed
        )
    ]
    
    static let sample1: ActivitiesRegister = .samples[0]
    static let sample2: ActivitiesRegister = .samples[1]
    static let sample3: ActivitiesRegister = .samples[2]
}
