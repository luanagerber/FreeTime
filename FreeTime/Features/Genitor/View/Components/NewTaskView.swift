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
    @State private var selectedActivity: Activity?
    @State private var isSaving = false
    
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
                                selectedActivity = option
                                titleTask = option.name
                                descriptionTask = option.description
                                coinsTask = String(option.rewardPoints)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(titleTask)
                                .foregroundColor(titleTask == "Selecione" ? .secondary : .primary)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(titleTask == "Selecione" ? Color.red.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Campo de descrição da atividade
                HStack {
                    Text(descriptionTask)
                        .foregroundColor(descriptionTask == "Descrição" ? .secondary : .primary)
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
                            .foregroundColor(.secondary)
                    } else {
                        Text(coinsTask)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.orange)
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
                            in: Date()..., // Só permite datas futuras
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
            
            // Mensagem de erro se houver
            if !canSave && titleTask == "Selecione" {
                Text("Selecione uma atividade para continuar")
                    .font(.caption)
                    .foregroundColor(.red)
                    .hSpacing(.leading)
            }
            
            // Salvar
            Button(action: {
                saveActivity()
            }, label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Salvar")
                    }
                }
                .font(.custom("SF Pro", size: 17, relativeTo: .body))
                .fontWeight(.bold)
                .foregroundColor(canSave ? .white : .secondary)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(canSave ? Color.blue : Color.gray.opacity(0.3))
                .cornerRadius(40)
            })
            .disabled(!canSave || isSaving)
            .padding(.bottom, 100)
        }
        .padding()
        .onAppear {
            // Define a data padrão como uma hora a partir de agora
            dateTask = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        selectedActivity != nil &&
        !isSaving &&
        dateTask > Date() &&
        viewModel.firstKid != nil
    }
    
    // MARK: - Methods
    
    private func saveActivity() {
        guard let activity = selectedActivity,
              let kid = viewModel.firstKid else {
            return
        }
        
        isSaving = true
        
        // 1. Configura os dados no ViewModel (igual ao GenitorCalendarView)
        viewModel.selectedKid = kid
        viewModel.selectedActivity = activity
        viewModel.scheduledDate = dateTask
        viewModel.duration = TimeInterval(3600) // 1 hora padrão
        
        // 2. Chama o mesmo método que GenitorCalendarView usa
        viewModel.scheduleActivity()
        
        // 3. Monitora o completion via Task
        Task {
            // Aguarda o ViewModel terminar o processamento
            while viewModel.isLoading {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundo
            }
            
            await MainActor.run {
                handleSaveCompletion()
            }
        }
    }
    
    private func handleSaveCompletion() {
        isSaving = false
        
        // Verifica se foi sucesso pelo feedback message
        if viewModel.feedbackMessage.contains("✅") {
            // Sucesso - fecha a tela
            dismiss()
            viewModel.createNewTask = false
            
            // Atualiza a data atual do calendário se necessário
            if !Calendar.current.isDate(dateTask, inSameDayAs: viewModel.currentDate) {
                viewModel.currentDate = dateTask
            }
            
            print("✅ NewTaskView: Atividade agendada com sucesso via ViewModel")
        } else {
            // Erro - mantém a tela aberta para o usuário tentar novamente
            print("❌ NewTaskView: Erro ao agendar atividade: \(viewModel.feedbackMessage)")
        }
    }
}

#Preview {
    NewTaskView()
}
