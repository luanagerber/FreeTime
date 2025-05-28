//
//  ActivitiesMock.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

extension Activity {
    
    static let catalog: [Activity] = [
        Activity(
            name: "Ler um livro",
            imageName: "imageBook",
            tags: [.mentalExercise, .study],
            description: "Ajude seu filho a escolher um livro que ele goste. Separe um lugar tranquilo e confortável. Se puder, leia junto com ele para tornar o momento mais especial.",
            necessaryMaterials: ["Livro"],
            rewardPoints: 25
        ),
        Activity(
            name: "Desenhar e colorir",
            imageName: "imageBook",
            tags: [.mentalExercise, .study],
            description: "Separe lápis de cor, giz de cera, canetinhas e papéis ou desenhos para colorir. Deixe a criança soltar a imaginação!",
            necessaryMaterials: ["Papel A4", "Lápis de cor", "Giz de cerna", "Canetinhas"],
            rewardPoints: 50
        ),
        Activity(
            name: "Montar quebra-cabeça",
            imageName: "imageQuebraCabeca",
            tags: [.mentalExercise, .study],
            description: "Escolha um quebra-cabeça adequado à idade da criança. Se puder, monte junto com ele, incentivando a paciência e o raciocínio lógico.",
            necessaryMaterials: ["Quebra-cabeça"],
            rewardPoints: 15
        )
    ]
}
