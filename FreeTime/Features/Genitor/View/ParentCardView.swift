//
//  ParentCardView.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

struct ParentCardView: View {
    let record: Record
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(record.activity.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(timeRange(from: record.date, duration: record.duration))
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
        .cornerRadius(Contants.UI.cardCornerRadius)
    }
    
    private func timeRange(from startDate: Date, duration: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let endDate = startDate.addingTimeInterval(duration)
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

#Preview {
    ParentCardView(record: Record.sample1)
}
