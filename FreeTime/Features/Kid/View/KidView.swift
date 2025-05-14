//
//  ChildView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct KidView: View {
    
    @StateObject private var kidViewModel = ParentViewModel()
    
    //Testing the View with the mocked-up data
    let kidId: UUID = Record.sample1.child.id
    
    //Select the activities assigned to the child for today and organize them by hours.
    private var kidRecords : [Record] {
        kidViewModel.records.filter { $0.child.id == kidId && Calendar.current.isDate($0.date, inSameDayAs: Date())}
        .sorted { $0.date < $1.date }
    }
    
    //Separate activities into pending and completed
    private var notStartedRecords: [Record] {
        kidRecords.filter { $0.recordStatus == .notStarted }
    }
    
    private var completedRecords: [Record] {
        kidRecords.filter { $0.recordStatus == .completed }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Rectangle()
                .fill(.gray)
                .frame(maxWidth: .infinity, maxHeight: 126)
                .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                activitySection(
                    title: "Para fazer",
                    records: notStartedRecords,
                    emptyMessage: "Não há atividades a serem realizadas hoje."
                )
                if !completedRecords.isEmpty {
                    activitySection(
                        title: "Feito",
                        records: completedRecords,
                        emptyMessage: ""
                    )
                }
            }
            .frame(maxWidth: 929)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Atividades para hoje")
                .font(.system(size: 34, weight: .semibold))
            Text(Date().formattedDayTitle())
                .font(.system(size: 22))
        }
    }
    
    private func activitySection(title: String, records: [Record], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .medium))
            
            if records.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(records) { record in
                            CardActivity(record: record)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .top)
    }
}

extension Date {
    func formattedDayTitle(locale: Locale = Locale(identifier: "pt_BR")) -> String {
        let weekday = self.formatted(.dateTime.weekday(.wide).locale(locale)).capitalized
        let date = self.formatted(.dateTime.day().month(.wide).locale(locale))
        return "\(weekday) | \(date)"
    }
}



#Preview {
    KidView()
}
