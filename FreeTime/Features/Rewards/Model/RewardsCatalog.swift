//
//  RewardMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

extension Reward {
    
    static let sample = Reward(id: 0, name: "Tomar sorvete", cost: 10, image: "🍦")
    
    static let catalog: [Reward] = [
        Reward(id: 0, name: "Tomar sorvete", cost: 10, image: "🍦"),
        Reward(id: 1, name: "Cinema", cost: 30, image: "🍿"),
        Reward(id: 2, name: "Nintendo Switch", cost: 1000, image: "🎮"),
        Reward(id: 3, name: "Dormir tarde", cost: 20, image: "🛌"),
        Reward(id: 4, name: "Comprar um livro", cost: 50, image: "📚"),
        Reward(id: 5, name: "Pedir delivery", cost: 70, image: "🍔")
    ]
    
    // Helper method to find reward by ID
    static func find(by id: Int) -> Reward? {
        catalog.first { $0.id == id }
    }
}
