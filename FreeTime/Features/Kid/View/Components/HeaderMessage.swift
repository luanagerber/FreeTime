//
//  HeaderMessage.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 02/06/25.
//

import SwiftUI

struct HeaderMessage: View {
    let message: String
    let color: Color
    
    @State private var offset: CGFloat = HeaderMessageStateOffset.hidden.rawValue
    
    enum HeaderMessageStateOffset: CGFloat {
        case hidden = 900.0
        case shown = 0.0
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            CustomCornerShape(radius: 20, corners: [.topLeft, .bottomLeft])
                .fill(color)
                .shadow(
                    color: color == .errorMessage ? .errorMessageShadow : .messageShadow,
                    radius: 0, x: -8, y: 8
                )
                .frame(maxWidth: .infinity)
                .frame(height: 75)
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.text)
                .padding()
                .padding(.leading, 20)
                .fontDesign(.rounded)
        }
        .offset(x: offset + 10)
        .onAppear {
            withAnimation(.bouncy(duration: 1.00, extraBounce: -0.5)) {
                offset = HeaderMessageStateOffset.shown.rawValue
            }
            Task {
                try? await Task.sleep(for: .seconds(8))
                withAnimation(.bouncy(duration: 1.00, extraBounce: -0.5)) {
                    offset = HeaderMessageStateOffset.hidden.rawValue
                }
            }
        }
    }
}
