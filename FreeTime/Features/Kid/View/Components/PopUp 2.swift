//
//  PopUp.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 22/05/25.
//

import SwiftUI

struct PopUp: View {
    @Binding var showPopUp: Bool
    @State private var text: String = "Parabéns! Você concluiu a atividade com sucesso!"
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.green.opacity(0.7))
            .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: 86)
            .overlay {
                notificationContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
    }
    
    var notificationContent: some View {
        Text(text)
            .font(.title2)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var showPopup = true
    return PopUp(
        showPopUp: $showPopup,
    )
}

