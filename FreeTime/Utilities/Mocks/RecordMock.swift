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
            kid: Kid(name: "Fulana"),
            parent: Genitor(name: "Ciclana", kidsID: UUID()),
            activity: ActivityCloudkit.samples[0],
            date: Date(), // agora
            duration: 3600, // 1 hora
            recordStatus: .notStarted
        ),
        Record(
            kid: Kid(name: "Caquita"),
            parent: Genitor(name: "Bolinha", kidsID: UUID()),
            activity: ActivityCloudkit.samples[1],
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            recordStatus: .notStarted
        ),
        Record(
            kid: Kid(name: "Thom"),
            parent: Genitor(name: "Marcos", kidsID: UUID()),
            activity: ActivityCloudkit.samples[1],
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 5400, // 1h30min
            recordStatus: .completed
        )
    ]
    
    static let sample1: Record = .samples[0]
    static let sample2: Record = .samples[1]
    static let sample3: Record = .samples[2]
}
