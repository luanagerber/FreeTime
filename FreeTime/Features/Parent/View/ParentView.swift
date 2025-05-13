//
//  ParentView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct ParentView: View {
    @StateObject private var viewModel = RecordViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Atividades planejadas")
                .font(.title3)
                .fontWeight(.medium)
               
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.records) { record in
                        ParentCardView(record: record)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    ParentView()
}
