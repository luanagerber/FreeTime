//
//  CustomShadow.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//

import SwiftUI

struct CustomMessageShadow: ViewModifier {
    
    let color: Color?
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color ?? .messageShadow,radius: 0, x: 8, y: 8)
    }
}

extension View {
    public func customMessageShadow(color: Color? = nil) -> some View {
        modifier(CustomMessageShadow(color: color))
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 20)
        .position(x: 100, y: 100)
        .frame(maxWidth: .infinity, maxHeight: 100)
        .foregroundStyle(.errorMessage)
        .customMessageShadow(color: .errorMessageShadow)
        
       
}
