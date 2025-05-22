//
//  Contants.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

struct Constants {
    struct UI{
        static let cardCornerRadius: CGFloat = 26
        static let circleSize: CGFloat = 40
        
        struct Colors{
            // colors
            static let textCard: Color = .white.opacity(0.7)
            static let titleText: Color = .black
            static let subtitleText: Color = .black
            static let cardBackground: Color = .white.opacity(0.1)
            
            static let defaultBackground: Color = .white
            static let lightGray: Color = .gray.mix(with: .white, by: 0.6)
        }
        
        struct Sizes {
            static let rewardCardHeight: CGFloat = 200.0
            static let rewardCardWidth: CGFloat = 360.0
            static let cardCornerRadius: CGFloat = 20.0
        }
    }
}
