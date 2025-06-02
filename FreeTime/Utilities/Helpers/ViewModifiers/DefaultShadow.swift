//
//  IupiCustomShadow.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//

import SwiftUI

struct DefaultShadow: ViewModifier {
    
    let color: Color?
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color ?? .black, radius: 4, x: 4, y: 4)
    }
}

extension View {
    func defaultShadow(color: Color? = nil) -> some View {
        self.modifier(DefaultShadow(color: color))
    }
}

#Preview {
    Circle()
        .frame(width: 200)
        .defaultShadow()
}
