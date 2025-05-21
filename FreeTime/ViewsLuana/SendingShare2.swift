//
//  SendingShare2.swift
//  FreeTime
//
//  Created by Luana Gerber on 21/05/25.
//

import SwiftUI
import CloudKit

struct SendingShare2: View {
    @AppStorage("userRole") private var userRole: String?
    
    private var cloudService: CloudService = .shared

    var body: some View {

            VStack{
                Text("Adicionar Criança")
                    .font(.title)
                    .foregroundStyle(.blue)
                
            }
    }

}

#Preview {
    SendingShare2()
}
