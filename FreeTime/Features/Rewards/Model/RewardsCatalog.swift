//
//  RewardMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

#warning("Poderia estar em no arquivo Reward.swift.")

extension Reward {
    
    static let sample = Reward(id: 0, name: "Tomar sorvete", cost: 10, image: "🍦")
    
    static let catalog: [Reward] = [
        Reward(id: 1, name: "Ganhar brinquedo", cost: 75, image: "🎁"),
        Reward(id: 2, name: "Ir ao cinema", cost: 30, image: "🍿"),
        Reward(id: 3, name: "Comida preferida", cost: 40, image: "🍕"), // Ex: Uma pizza especial ou prato favorito
        Reward(id: 4, name: "Ganhar dinheiro", cost: 100, image: "💰"),      // Ex: Uma mesada extra
        Reward(id: 5, name: "Festa do pijama", cost: 20, image: "🥳"),
        Reward(id: 6, name: "Escolher passeio", cost: 25, image: "🏞️"),       // Ex: Um passeio no parque
        Reward(id: 7, name: "Fazer piquenique", cost: 35, image: "🧺"),
        Reward(id: 8, name: "Ir para a praia", cost: 60, image: "🏖️"),
        Reward(id: 9, name: "Viagem", cost: 500, image: "✈️"),
        Reward(id: 10, name: "Ir ao zoologico", cost: 45, image: "🐘")
    ]
    
    // Helper method to find reward by ID
    static func find(by id: Int) -> Reward? {
        catalog.first { $0.id == id }
    }
    
}
