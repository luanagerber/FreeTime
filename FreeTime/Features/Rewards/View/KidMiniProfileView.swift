//
//  KidMiniProfileView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 26/05/25.
//

import SwiftUI

struct KidMiniProfileView: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
