//
//  ParentCardView.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

struct GenitorTaskRowView: View {
    let record: ActivitiesRegister
    
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
            
//            Circle()
//                .fill(Color.gray)
//                .frame(width: 40, height: 40)
        }
        .padding(22)
        .frame(width: 350, height: 116, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cardCornerRadius)
    }
    
}

#Preview {
    GenitorTaskRowView(record: ActivitiesRegister.sample1)
}
