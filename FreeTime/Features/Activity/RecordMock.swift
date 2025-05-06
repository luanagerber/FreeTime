//
//  RecordMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

extension Record {
    static let sample1 = Record(
        child: Child(name: "Fulana", parentID: UUID()),
        parent: Parent(name: "Ciclana", childrenID: UUID()),
        activity: Activity.sample1,
        date: Date(), // agora
        duration: 3600 // 1 hora
    )
    
    static let sample2 = Record(
        child: Child(name: "Caquita", parentID: UUID()),
        parent: Parent(name: "Bolinha", childrenID: UUID()),
        activity: Activity.sample2,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        duration: 5400 // 1h30min
    )
}
