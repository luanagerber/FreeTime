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
            name: "Desenhar e colorir desenho",
            imageNameGenitor: "imageDrawGenitor",
            imageNameKid: "Zoologico",
            tags: [.creativity],
            description: "Separe lápis de cor, giz de cera, canetinhas e papéis ou desenhos para colorir. Deixe a criança soltar a imaginação!",
            kidDescription: "Use lápis, canetinhas ou o que tiver em casa para criar um desenho bem legal. Depois, pinte com as cores que mais combinarem com a sua ideia!",
            necessaryMaterials: ["Papel", "Lápis", "Borracha", "Pincéis"],
            rewardPoints: 10
        ),
        Activity(
            id: 1,
            name: "Ler livro",
            imageNameGenitor: "imageBookGenitor",
            imageNameKid: "imageBookKid",
            tags: [.mentalExercise, .study],
            description: "Ajude seu filho a escolher um livro que ele goste. Separe um lugar tranquilo e confortável. Se puder, leia junto com ele para tornar o momento mais especial.",
            kidDescription: "Vamos fazer um vulcão que explode! Prepare-se para a diversão científica!",
            necessaryMaterials: ["Livro"],
            rewardPoints: 20
        ),
        Activity(
            id: 2,
            name: "Montar quebra-cabeça",
            imageNameGenitor: "imagePuzzleGenitor",
            imageNameKid: "imagePuzzeKid",
            tags: [.creativity],
            description: "Escolha um quebra-cabeça adequado à idade da criança. Se puder, monte junto com ele, incentivando a paciência e o raciocínio lógico",
            kidDescription: "Escolha um quebra-cabeça que você goste e monte com calma, prestando atenção nas cores e nas formas. Tenha concentração e paciência para encaixar cada peça no lugar certo!",
            necessaryMaterials: ["Espaço livre", "Amigos"],
            rewardPoints: 15
        )
    ]
    
    // Helper method to find activity by ID
    static func find(by id: Int) -> Activity? {
        catalog.first { $0.id == id }
    }

}
