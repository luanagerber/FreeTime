//
//  ChildView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//
import SwiftUI

struct ChildView: View {
    //Testing the View with the mocked-up data
    let childId: UUID = Record.sample3.child.id
    
    //Asks to select all the records associated with the child's ID
    var childRecords: [Record] {
        records(for: childId, from: Record.samples)
    }
    
    var body: some View {
        
        VStack(spacing: 32) {
            Rectangle()
                .fill(.gray)
                .frame(maxWidth: .infinity, maxHeight: 126)
                .cornerRadius(20)
            
            
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                activitySection(title: "Para fazer", status: .notStarted, message: "Não há atividades atribuídas para o dia.")
                
                if !childRecords.filter({ $0.recordStatus == .completed }).isEmpty {
                    activitySection(title: "Feito", status: .completed, message: "")
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
            Text(Record.sample1.date.formattedDayTitle())
                .font(.system(size: 22))
        }
    }
    
    private func activitySection(title: String, status: RecordState, message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .medium))
            
            let filteredRecords = childRecords.filter { $0.recordStatus == status }
            
            if filteredRecords.isEmpty {
                Text(message)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(filteredRecords) { record in
                            CardActivity(record: record)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .top)
    }

    
    
    
    //Gets the records associated with the child's ID
    private func records(for childID: UUID, from records: [Record]) -> [Record] {
        records.filter { $0.child.id == childID }
    }
}


extension Date {
    func formattedDayTitle(locale: Locale = Locale(identifier: "pt_BR")) -> String {
        let weekday = self.formatted(.dateTime.weekday(.wide).locale(locale)).capitalized
        let date = self.formatted(.dateTime.day().month(.wide).year().locale(locale))
        return "\(weekday) | \(date)"
    }
}


#Preview {
    ChildView()
}

//Tenho que atualizar para quando os registros forem empty

//Caso 1 : Há Atividade para fazer e concluídas OK
//Caso 2: Há Atividade para fazer e nenhuma foi concluída
//Caso 3: Não há atividades para fazer e todas foram concluídas
//Caso 2: Não há atividade atribuídas para o dia
