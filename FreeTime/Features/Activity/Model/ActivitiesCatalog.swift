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
            materials: ["Tinta guache", "Papel A3", "Pincéis"],
        ),
        Activity(
            name: "Experimento de Vulcão",
            tags: [.mentalExercise, .study],
            description: "Construção de um vulcão com bicarbonato e vinagre.",
            materials: ["Bicarbonato de sódio", "Vinagre", "Argila", "Corante alimentício"],
        )
    ]
}
