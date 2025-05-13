//
//  ParentView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct ParentView: View {
    var body: some View {
        VStack {
            ForEach(Record.samples) { record in
                Text(record.activity.name)
            }
        }
    }
}

#Preview {
    ParentView()
}
