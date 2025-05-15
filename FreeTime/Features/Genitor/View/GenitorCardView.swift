//
//  ParentCardView.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

struct GenitorCardView: View {
    let record: Register
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(record.activity?.name ?? "no name")
                    .font(.body)
                    .fontWeight(.medium)
                Text(record.date.timeRange(duration: record.duration))
                    .font(.body)
                    .fontWeight(.regular)
            }
            Spacer()
            Circle()
                .fill(Color.gray)
                .frame(width: 40, height: 40)
        }
        .padding(22)
        .frame(width: 350, height: 161, alignment: .bottomLeading)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cardCornerRadius)
    }
    
}

#Preview {
    GenitorCardView(record: Register.sample1)
}
