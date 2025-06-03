//
//  ActivitySection.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//
import SwiftUI

struct ActivitySection: View {
    let registers: [ActivitiesRegister]
    let emptyMessage: String
    @Binding var selectedRegister: ActivitiesRegister?
    var vmKid: KidViewModel
    @Binding var showPopUp: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if registers.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(registers) { register in
                            Button {
                                selectedRegister = register
                            } label: {
                                CardActivity(register: register)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedRegister) { register in
            DetailView(kidViewModel: vmKid, register: register,  onCompletion: {
               
                    showPopUp = true
            })
        }
    }
}
