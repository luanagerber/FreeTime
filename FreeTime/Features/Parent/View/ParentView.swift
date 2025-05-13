//
//  ParentView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct ParentView: View {
    @StateObject private var viewModel = ParentViewModel()
    
    var body: some View {
        ScrollView {
            Text("Atividades planejadas")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVStack(alignment: .center, spacing: 20) {
                if viewModel.records.isEmpty {
                    Text("Nenhuma atividade foi planejada ainda. Clique em \"+\" para começar!")
                        .padding(.horizontal)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    
                } else {
                    ForEach(viewModel.records.filter({$0.recordStatus == .notStarted})) { record in
                        ParentCardView(record: record)
                    }
                }
            }
            
            Spacer(minLength: 34)
            
            Text("Atividades concluídas")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVStack(alignment: .center, spacing: 20) {
                if viewModel.records.filter({$0.recordStatus == .completed}).isEmpty {
                    Text("Nada foi concluído hoje ainda. Que tal checar com seu filho?")
                        .padding(.horizontal)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(viewModel.records.filter({$0.recordStatus == .completed})) { record in
                        ParentCardView(record: record)
                    }
                }
            }
        }
    }
}

#Preview {
    ParentView()
}
