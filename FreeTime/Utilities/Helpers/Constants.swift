//
//  Contants.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

#warning("Cuidado com magic numbers...")

struct Constants {
    struct UI{
        static let cardCornerRadius: CGFloat = 20
        static let circleSize: CGFloat = 40
        static let tabBarHeight: CGFloat = 90
        
        struct Colors{
            // colors
            static let textCard: Color = .text
            static let titleText: Color = .text
            static let subtitleText: Color = .text
            static let cardBackground: Color = .white.opacity(0.1)
            
            static let defaultBackground: Color = .defaultBackground
            static let lightGray: Color = .gray.mix(with: .white, by: 0.6)
        }
        
        struct Sizes {
            static let rewardCardHeight: CGFloat = 200.0
            static let rewardCardWidth: CGFloat = 360.0
            static let cardCornerRadius: CGFloat = 20.0
        }
    }
}
