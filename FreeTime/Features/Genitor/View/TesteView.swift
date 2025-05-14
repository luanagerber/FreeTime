//
//  TesteView.swift
//  FreeTime
//
//  Created by Thales Araújo on 14/05/25.
//

import SwiftUI

extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

struct TesteView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(0..<30) { _ in
                    Color.random()
                        .containerRelativeFrame(
                            .horizontal,
                            count: 7,
                            
                            spacing: 0
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
    }
}

#Preview {
    TesteView()
}
