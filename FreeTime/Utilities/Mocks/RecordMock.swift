//
//  RecordMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

extension Record {
    static let samples: [Record] = [
        Record(
            child: Kid(name: "Fulana", parentID: UUID()),
            parent: Parent(name: "Ciclana", childrenID: UUID()),
            activity: Activity.samples[0],
            date: Date(), // agora
            duration: 3600, // 1 hora
            recordStatus: .notStarted
        ),
        Record(
            child: Kid(name: "Caquita", parentID: UUID()),
            parent: Parent(name: "Bolinha", childrenID: UUID()),
            activity: Activity.samples[1],
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            recordStatus: .inProgress
        ),
        Record(
            child: Kid(name: "Thom", parentID: UUID()),
            parent: Parent(name: "Marcos", childrenID: UUID()),
            activity: Activity.samples[1],
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            recordStatus: .inProgress
        )
    ]
}
