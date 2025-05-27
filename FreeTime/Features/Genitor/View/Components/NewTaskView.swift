//
//  NewTaskView.swift
//  FreeTime
//
//  Created by Thales Araújo on 27/05/25.
//

import SwiftUI

struct NewTaskView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = GenitorViewModel.shared
    
    @State private var titleTask: String = "Selecione"
    @State private var descriptionTask: String = "Descrição"
    @State private var coinsTask: String = "-"
    @State private var dateTask: Date = .init()
    
    @State private var isShowingPicker = false
    
    var body: some View {
        VStack (spacing: 40){
            
            // Botão de cancelar
            Button(action: {
                dismiss()
                viewModel.createNewTask = false
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .tint(Color.gray)
            })
            .hSpacing(.bottomTrailing)
            
            // Título
            Text("Nova atividade")
                .font(.custom("SF Pro", size: 20, relativeTo: .title3))
                .fontWeight(.semibold)
                .hSpacing(.leading)
            
            // Atividade
            VStack (spacing: 20) {
                // Campo do nome da atividade
                HStack {
                    Text("Atividade")
                    
                    Spacer()
                    
                    Menu{
                        ForEach(Activity.catalog, id: \.self) { option in
                            Button(option.name) {
                                titleTask = option.name
                                descriptionTask = option.description
                                coinsTask = String(option.rewardPoints)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(titleTask)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Campo de descrição da atividade
                HStack {
                    Text(descriptionTask)
                }
                .hSpacing(.leading)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Campo de moedas da atividade
                HStack {
                    Text("Valor da atividade")
                    
                    Spacer()
                    
                    if coinsTask == "-" {
                        Text(coinsTask)
                    } else {
                        Text(coinsTask)
                        
                        Image(systemName: "dollarsign.circle.fill")
                    }
                }
                .hSpacing(.leading)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Campo para escolher data
                VStack {
                    HStack {
                        Text("Data")
                        Spacer()
                        
                        Button {
                            withAnimation {
                                isShowingPicker.toggle()
                            }
                        } label: {
                            Text(dateTask.formattedAsDayMonthAndHour())
                        }
                    }
                    
                    if isShowingPicker {
                        Divider()
                        DatePicker(
                            "",
                            selection: $dateTask,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .transition(.opacity)
                    }
                }
                .hSpacing(.leading)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Salvar
            Button(action: {
                
            }, label: {
                Text("Salvar")
                    .font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.vertical, 16) // altura do botão
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(40)
                
            })
            .padding(.bottom, 100)
            
            
            
            
        }
        .padding()
    }
}

#Preview {
    NewTaskView()
}
