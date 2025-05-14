//
//  KidView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct KidView: View {
    @StateObject private var kidViewModel = KidViewModel()
    
    //Testing with mocked-up data
    let kidExemple : Kid = Record.sample1.kid
    let kidId: UUID = Record.sample1.kid.id
    //
    
    var body: some View {
        VStack(spacing: 32) {
            
            Section {
                SectionProfile(kid: kidExemple)
            }
            
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                activitySection(
                    title: "Para fazer",
                    records: kidViewModel.notStartedRecords(kidId: kidId),
                    emptyMessage: "Não há atividades a serem realizadas hoje."
                )
                
                let completed = kidViewModel.completedRecords(kidId: kidId)
                if !completed.isEmpty {
                    activitySection(
                        title: "Feito",
                        records: completed,
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
    
    private func activitySection(title: String, records: [Register], emptyMessage: String) -> some View {
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

#Preview {
    KidView()
}
