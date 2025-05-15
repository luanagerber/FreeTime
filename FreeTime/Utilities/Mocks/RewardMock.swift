//
//  RewardMock.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation

extension Reward {
    
    static let sample = Reward(name: "Tomar sorvete", cost: 10, image: "🍦")
    
    static let samples: [Reward] =  [
        Reward(name: "Tomar sorvete", cost: 10, image: "🍦"),
        Reward(name: "Cinema", cost: 30, image: "🍿"),
        Reward(name: "Nintendo Switch", cost: 1000, image: "🎮"),
        Reward(name: "Dormir tarde", cost: 20, image: "🛌"),
        Reward(name: "Comprar um livro", cost: 50, image: "📚"),
        Reward(name: "Pedir delivery", cost: 70, image: "🍔")
        ]
    
}
