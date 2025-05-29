//
//  KeyboardResponder.swift
//  FreeTime
//
//  Created by Thales Araújo on 28/05/25.
//

import SwiftUI
import Combine

struct KeyboardResponder: ViewModifier {
    @State private var offset: CGFloat = 0
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

    func body(content: Content) -> some View {
        content
            .padding(.bottom, offset)
            .onReceive(keyboardWillShow) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation {
                        offset = keyboardFrame.height * 0.6
                    }
                }
            }
            .onReceive(keyboardWillHide) { _ in
                withAnimation {
                    offset = 0
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardResponder())
    }
}
