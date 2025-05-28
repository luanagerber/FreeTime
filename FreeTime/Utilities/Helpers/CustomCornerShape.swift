//
//  CustomCornerShape.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 26/05/25.
//

import SwiftUI

struct CustomCornerShape: Shape {
    var radius: CGFloat // O raio do arredondamento
    var corners: UIRectCorner // Os cantos a serem arredondados

    // Esta função define o caminho da forma dentro de um retângulo específico.
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
