//
//  NavBarView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//

import SwiftUI

struct NavBarView: View {
    let isSelected: Bool
    let page: Page
    
    var body: some View {
        ZStack {
            CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight])
                .fill(.capsuleCoin)
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity)
                .overlay(
                    // Aplica a borda APENAS se isSelected for true
                    Group {
                        if isSelected {
                            CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight])
                                .stroke(.text, lineWidth: 2) // Cor e espessura da borda
                                .ignoresSafeArea(edges: .top)
                                .frame(maxHeight: .infinity)
                        }
                    }
                )
                
            
            VStack(spacing: 9){
                Image(ImageFromPage(page).rawValue)
                Text(TextFromPage(page).rawValue)
                    .defaultText()
                    .fontWeight(isSelected ? .medium : .regular)
                    .font(.title2)
            }
            .padding(.top, 10)
        }
        
    }
    
    enum ImageFromPage: String {
        case homeIcon
        case toDoIcon
        
        init (_ page: Page) {
            switch page {
            case .rewardsStore:
                self = .homeIcon
            default:
                self = .toDoIcon
            }
        }
    }
    
    enum TextFromPage: String {
        case home = "Lojinha"
        case toDo = "Atividades"
        
        init (_ page: Page) {
            switch page {
            case .rewardsStore:
                self = .home
            default:
                self = .toDo
            }
        }
    }
}

#Preview("Nao selecionada"){
    NavBarView(isSelected: false, page: .rewardsStore)
}

#Preview("Selecionada"){
    NavBarView(isSelected: true, page: .rewardsStore)
}
