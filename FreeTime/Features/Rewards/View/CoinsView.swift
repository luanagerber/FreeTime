//
//  CoinsView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 26/05/25.
//

import SwiftUI

struct CoinsView : View {
    let amount: Int
    let opacity: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(.yellow)
                .imageScale(.large)
            Text("\(amount)")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(2)
        .background(Color.yellow.opacity(opacity))
        .cornerRadius(10)
    }
}

