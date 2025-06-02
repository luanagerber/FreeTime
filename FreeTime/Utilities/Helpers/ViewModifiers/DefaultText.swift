//
//  DefaultText.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//

import SwiftUI

struct DefaultText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.text)
            .fontDesign(.rounded)
    }
}

extension View {
    func defaultText() -> some View {
        modifier(DefaultText())
    }
}

#Preview {
    Text("oi")
        .defaultText()
}
