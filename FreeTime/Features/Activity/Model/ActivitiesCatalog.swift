//
//  ActivitiesMock.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

extension Activity {
    
    static let catalog: [Activity] = [
        Activity(
            name: "Pintura Criativa",
            tags: [.mentalExercise, .study],
            description: "Uma atividade de pintura livre para estimular a criatividade das crianças.",
            necessaryMaterials: ["Tinta guache", "Papel A3", "Pincéis"],
            rewardPoints: 50
        ),
        Activity(
            name: "Experimento de Vulcão",
            tags: [.mentalExercise, .study],
            description: "Construção de um vulcão com bicarbonato e vinagre.",
            necessaryMaterials: ["Bicarbonato de sódio", "Vinagre", "Argila", "Corante alimentício"],
            rewardPoints: 50
        )
    ]
}
