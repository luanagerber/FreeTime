//
//  ParentDetailView.swift
//  FreeTime
//
//  Created by Thales Araújo on 07/05/25.
//

import SwiftUI

struct ParentDetailView: View {
    var text: String
    
    var body: some View {
        ZStack(alignment: .leading){
            Rectangle()
                .foregroundStyle(Color.yellow)
                
            Text(text)
        }
        .frame(width: 100, height: 100)
        .cornerRadius(20)
    }
}

#Preview {
    ParentDetailView(text: "teste")
}
