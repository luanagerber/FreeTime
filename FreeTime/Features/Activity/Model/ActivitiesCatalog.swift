//
//  ActivitiesCatalog.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

extension Activity {
    
    static let catalog: [Activity] = [
        Activity(
            id: 0,
            name: "Pintura Criativa",
            tags: [.mentalExercise, .study],
            description: "Uma atividade de pintura livre para estimular a criatividade das crianças.",
            kidDescription: "Hora de soltar a imaginação! Pinte algo super legal e colorido!",
            necessaryMaterials: ["Tinta guache", "Papel A3", "Pincéis"],
            rewardPoints: 25
        ),
        Activity(
            id: 1,
            name: "Experimento de Vulcão",
            tags: [.mentalExercise, .study],
            description: "Construção de um vulcão com bicarbonato e vinagre.",
            kidDescription: "Vamos fazer um vulcão que explode! Prepare-se para a diversão científica!",
            necessaryMaterials: ["Bicarbonato de sódio", "Vinagre", "Argila", "Corante alimentício"],
            rewardPoints: 50
        ),
        Activity(
            id: 2,
            name: "Brincar de esconde esconde",
            tags: [.physicalExercise, .socialActivity],
            description: "Correr com os amigos",
            kidDescription: "Hora de brincar de esconder! Quem vai conseguir se esconder melhor?",
            necessaryMaterials: ["Espaço livre", "Amigos"],
            rewardPoints: 15
        )
    ]
    
    // Helper method to find activity by ID
    static func find(by id: Int) -> Activity? {
        catalog.first { $0.id == id }
    }

}
