//
//  ChildView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct ChildView: View {
    //testing a view with the mocked-up data
    let childId: UUID =  Record.sample2.child.id
    
    var childRecords: [Record] { // filter the records associated with the child's id
        records(for: childId, from: Record.samples)
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Header
                HStack {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                    
                    VStack {
                        Text("Nome")
                            .font(.largeTitle)
                            .bold()
                        Text("$100")
                            .font(.title)
                            .bold()
                    }
                    
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                    
                    Text("Vamos fazer a\natividade de hoje?")
                        .font(.largeTitle)
                        .bold()
                }
                
                Text("Atividades para hoje")
                    .font(.largeTitle)
                
                Text("Dia da semana, data, mês")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(childRecords.filter { $0.recordStatus == .notStarted }) { record in
                            CardActivity(record: record)
                        }
                    }
                }
                Text("Atividades Concluídas")
                    .font(.largeTitle)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(childRecords.filter { $0.recordStatus == .completed }) { record in
                            CardActivity(record: record)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}


func records(for childID: UUID, from records: [Record]) -> [Record] {
    records.filter { $0.child.id == childID }
}

#Preview {
    ChildView()
}
