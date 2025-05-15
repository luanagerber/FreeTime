//
//  RecordMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation

extension Register {
    static let samples: [Register] = [
        Register(
            kid: Kid(name: "Fulana"),
            genitor: Genitor(name: "Ciclana", kidsID: UUID()),
            activityID: Activity.catalog[0].id,
            date: Date(), // agora
            duration: 3600, // 1 hora
            registerStatus: .notStarted
        ),
        Register(
            kid: Kid(name: "Caquita"),
            genitor: Genitor(name: "Bolinha", kidsID: UUID()),
            activityID: Activity.catalog[1].id,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            registerStatus: .notStarted
        ),
        Register(
            kid: Kid(name: "Thom"),
            genitor: Genitor(name: "Marcos", kidsID: UUID()),
            activityID: Activity.catalog[1].id,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            registerStatus: .completed
        )
    ]
    
    static let sample1: Register = .samples[0]
    static let sample2: Register = .samples[1]
    static let sample3: Register = .samples[2]
}
