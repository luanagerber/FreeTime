//
//  RewardToImage.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 27/05/25.
//

import SwiftUI

// mocked solution
enum RewardToImageMap {
    
    case brinquedo
    case cinema
    case comidaPreferida
    case dinheiro
    case festaDoPijama
    case passeio
    case piquenique
    case praia
    case shopping
    case zoologico
    case placeholder // quando nao é nenhum dos casos
    
    init(reward: Reward) {
        switch reward.name {
        case "Ganhar brinquedo":
            self = .brinquedo
        case "Ir ao cinema":
            self = .cinema
        case "Comida preferida":
            self = .comidaPreferida
        case "Ganhar dinheiro":
            self = .dinheiro
        case "Festa do pijama":
            self = .festaDoPijama
        case "Escolher passeio":
            self = .passeio
        case "Fazer piquenique":
            self = .piquenique
        case "Ir para a praia":
            self = .praia
        case "Ir ao shopping":
            self = .shopping
        case "Ir ao zoologico":
            self = .zoologico
        default:
            self = .placeholder
        }
    }
    
    var imageName: String {
        switch self {
        case .brinquedo:
            return "Brinquedo"
        case .cinema:
            return "Cinema"
        case .comidaPreferida:
            return "ComidaPreferida"
        case .dinheiro:
            return "Dinheiro"
        case .festaDoPijama:
            return "FestaDoPijama"
        case .passeio:
            return "Passeio"
        case .piquenique:
            return "Piquenique"
        case .praia:
            return "Praia"
        case .shopping:
            return "Viagem"
        case .zoologico:
            return "Zoologico"
        case .placeholder:
            return "defaultRewardIcon"
        }
    }
}
