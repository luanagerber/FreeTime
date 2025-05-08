<<<<<<< HEAD
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
=======
>>>>>>> 168072d4db05b7f6128a66878a568845aaa7c08b

