//
//  GenitorTaskRowView.swift
//  FreeTime
//
//  Created by Thales Araújo on 08/05/25.
//

import SwiftUI

struct GenitorTaskRowView: View {
    let record: ActivitiesRegister
    
    private var statusColor: Color {
        switch record.registerStatus {
        case .notStarted:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        }
    }
    
    private var statusIcon: String {
        switch record.registerStatus {
        case .notStarted:
            return "clock"
        case .inProgress:
            return "play.circle"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var statusDisplayName: String {
        switch record.registerStatus {
        case .notStarted:
            return "Agendada"
        case .inProgress:
            return "Em Progresso"
        case .completed:
            return "Concluída"
        }
    }
    
    var body: some View {
        HStack {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(record.activity?.name ?? "Atividade Desconhecida")
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text(record.date.timeRange(duration: record.duration))
                        .font(.body)
                        .fontWeight(.regular)
                    
                    Spacer()
                    
                    // Status badge
                    Text(statusDisplayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius)
                .stroke(statusColor.opacity(0.3), lineWidth: record.registerStatus == .completed ? 2 : 0)
        )
    }
}

#Preview {
    GenitorTaskRowView(record: ActivitiesRegister.sample1)
}
