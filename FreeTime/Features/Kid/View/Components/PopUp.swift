//
//  PopUp.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 22/05/25.
//

import SwiftUI

struct PopUp: View {
    @Binding var showPopUp: Bool
    var text: String = "Parabéns! Você concluiu a atividade com sucesso!"
    var color: Color = .message
    
    // Offset da animação
    @State private var offsetX: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack(alignment: .leading) {
            CustomCornerShape(radius: 20, corners: [.topLeft, .bottomLeft])
                .fill(color)
                .customMessageShadow()
                .frame(width: 578)
                .frame(height: 80)
            
            Text(text)
                .font(.title3)
                .fontWeight(.medium)
                .fontDesign(.rounded)
                .foregroundStyle(.text)
                .padding()
                .padding(.leading, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 180) 
        .padding(.trailing, 0)
        .ignoresSafeArea()
        .offset(x: offsetX)
        .onAppear {
            withAnimation(.bouncy(duration: 1.0, extraBounce: -0.5)) {
                offsetX = 0
            }
            
            Task {
                try? await Task.sleep(for: .seconds(8))
                withAnimation(.bouncy(duration: 1.0, extraBounce: -0.5)) {
                    offsetX = UIScreen.main.bounds.width
                }
                try? await Task.sleep(for: .seconds(1))
                showPopUp = false
            }
        }
    }
}

#Preview {
    @Previewable @State var showPopup = true
    return ZStack {
        Color.gray.ignoresSafeArea()
        if showPopup {
            PopUp(showPopUp: $showPopup)
        }
    }
}

