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
        HStack (spacing: 20){
            // Status indicator
            //            Image(systemName: statusIcon)
            //                .foregroundColor(statusColor)
            //                .font(.title2)
            
            Image(record.activity?.imageName ?? "")
                .resizable()
                .scaledToFill()
                .frame(
                    width: UIScreen.main.bounds.width * 0.2,
                    height: UIScreen.main.bounds.height * 0.09
                )
                .cornerRadius(15)
            
//            Rectangle()
//                .foregroundColor(.yellow)
//                .frame(
//                    width: UIScreen.main.bounds.width * 0.2,
//                    height: UIScreen.main.bounds.height * 0.09
//                )
//                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(record.activity?.name ?? "Atividade Desconhecida")
                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .fontWeight(.medium)
                    .foregroundStyle(Color("primaryColor"))
                
                //HStack {
                Text(record.date.formattedAsHourMinute())
                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .foregroundStyle(Color("primaryColor"))
                
                //                    Spacer()
                
                // Status badge
                //                    Text(statusDisplayName)
                //                        .font(.caption)
                //                        .padding(.horizontal, 8)
                //                        .padding(.vertical, 4)
                //                        .background(statusColor.opacity(0.2))
                //                        .foregroundColor(statusColor)
                //                        .cornerRadius(4)
                //}
            }
        }
        .padding(22)
        .frame(
            maxWidth: .infinity,
            minHeight: UIScreen.main.bounds.height*0.13,
            alignment: .leading
        )
        .background(.white)
        .cornerRadius(Constants.UI.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius)
                .inset(by: 0.5)
                .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 5, y: 5)
    }
}

#Preview {
    GenitorTaskRowView(record: ActivitiesRegister.sample1)
}
