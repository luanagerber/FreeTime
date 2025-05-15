//
//  DetailsActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import SwiftUI

struct DetailsActivityModal: View {
    @ObservedObject var kidViewModel: KidViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var register: Register
    
    var body: some View {
        VStack(alignment: .leading, spacing: 50){
            HStack {
                Text(register.activity.name)
                Spacer()
                Text("$5")
            }.font(.system(size: 34, weight: .semibold))
            
            Text(register.activity.description)
                .font(.system(size: 22))
            
            HStack {
                Text("Hora:")
                Spacer()
                Text(register.date.timeRange(duration: register.duration))
            }.font(.system(size: 22))
            
            Button {
                register.registerStatus = .completed
                kidViewModel.concludedActivity(register: register)
                dismiss()
                
                //Ajeitar
                
            } label: {
                Rectangle()
                    .frame(width: 150, height: 50)
                    .cornerRadius(20)
                    .overlay {
                        Text("Concluído")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(100)
        .background(Color.gray.opacity(0.5))
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(10)
        }
    }
}
//
//#Preview {
//    DetailsActivityModal(kidViewModel: KidViewModel(), register: Register.sample1)
//}
