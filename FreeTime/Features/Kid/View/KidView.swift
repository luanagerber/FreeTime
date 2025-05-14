//
//  ChildView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct KidView: View {
    //testing a view with the mocked-up data
    let childId: UUID =  Record.sample2.child.id
    
    var childRecords: [Record] { // filter the records associated with the child's id
        records(for: childId, from: Record.samples)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .fill(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 126)
                    .cornerRadius(12)
                    
                    
                
                   
                
                
                Text("Atividades para hoje")
                    .font(.largeTitle)
                    .font(.system(size: 34, weight: .bold, design: .default))
                
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
            }.frame(maxHeight: .infinity, alignment: .top)
                .border(.black)
            .ignoresSafeArea()
        }
    }
}


func records(for childID: UUID, from records: [Record]) -> [Record] {
    records.filter { $0.child.id == childID }
}

#Preview {
    KidView()
}
