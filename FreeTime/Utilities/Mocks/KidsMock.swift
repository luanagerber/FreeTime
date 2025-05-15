//
//  KidMock.swift
//  FreeTime

import Foundation

extension Kid {
    
    static let sample = Kid(
        name: "Lucas",
        parentID: UUID(), // Pode ser substituído por um UUID fixo para testes
        coins: 120
    )
    
    static let samples: [Kid] = [
        Kid(name: "Lucas", parentID: UUID(), coins: 120),
        Kid(name: "Sofia", parentID: UUID(), coins: 80),
        Kid(name: "Mateus", parentID: UUID(), coins: 200)
    ]
}
