//
//  GridView.swift
//  FreeTime
//
//  Created by Thales Araújo on 14/05/25.
//

import SwiftUI

struct LazyHGridExample: View {
    
    let itens = Array(1...30)
    
//    var body: some View {
//        GeometryReader { geo in
//            let item = (geo.size.width - 60) / 8
//            ScrollView(.horizontal) {
//                LazyHStack(spacing: 15) {
//                    ForEach(0..<30) { index in
//                        Rectangle()
//                            .fill(Color.blue)
//                            .frame(width: item, height: item)
//                            .overlay(Text("\(index)").foregroundColor(.white))
//                    }
//                }
//                .scrollTargetLayout()
//                .padding(.leading, 15)
//            }
//            .scrollTargetBehavior(.paging)
//        }
//    }
    
    let allItems = Array(1...30)
        
        // Agrupa itens em subarrays de 7 elementos
        var groupedItems: [[Int]] {
            stride(from: 0, to: allItems.count, by: 7).map {
                Array(allItems[$0..<min($0 + 7, allItems.count)])
            }
        }
        
        var body: some View {
            GeometryReader { geo in
                let spacing: CGFloat = 10
                let totalSpacing = spacing * 6  // 6 espaços entre 7 itens
                let itemWidth = (geo.size.width - totalSpacing) / 7
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(groupedItems.indices, id: \.self) { groupIndex in
                            HStack(spacing: spacing) {
                                ForEach(groupedItems[groupIndex], id: \.self) { item in
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: itemWidth, height: itemWidth)
                                        .overlay(Text("\(item)").foregroundColor(.white))
                                }
                            }
                            .frame(width: geo.size.width)  // Cada grupo ocupa a largura total da tela
                            .scrollTargetLayout()          // Marca o grupo como alvo do scroll paginado
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
            }
            .frame(height: 150)
        }
}

#Preview {
    LazyHGridExample()
}
