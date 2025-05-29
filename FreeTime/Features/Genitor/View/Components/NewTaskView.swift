//
//  NewTaskView.swift
//  FreeTime
//
//  Created by Thales Araújo on 27/05/25.
//
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
                .foregroundStyle(Color("primaryColor"))
                .hSpacing(.leading)
            
            // Preenchimento dos campos
            VStack (spacing: 20) {
                // nome da atividade
                HStack {
                    Text("Atividade")
                        .font(.custom("SF Pro", size: 17, relativeTo: .title3))
                        .fontWeight(.medium)
                        .foregroundStyle(Color("primaryColor"))
                    
                    Spacer()
                    
                    Menu{
                        ForEach(Activity.catalog, id: \.self) { option in
                            Button(option.name) {
                                selectedActivity = option
                                titleTask = option.name
                                descriptionTask = option.getDescription(for: .genitor)
                                coinsTask = String(option.rewardPoints)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            
                            Text(titleTask)
                            
                            Image(systemName: "chevron.up.chevron.down")
                            
                        }
                        .foregroundColor(Color("backgroundTaskActivitySelected"))
                    }
                }
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            titleTask == "Selecione"
                            ? Color("backgroundTaskActivitySelected")
                            : Color(red: 0.87, green: 0.87, blue: 0.87)
                            , lineWidth: 2)
                )
                
                // descrição da atividade
                HStack {
                    Text(descriptionTask)
                        .foregroundColor(Color("primaryColor").opacity(0.4))
                        
                        .hSpacing(.leading)
                        .padding()
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // valor da atividade
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
                
                .foregroundColor(Color("primaryColor").opacity(0.4))
                .hSpacing(.leading)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // Campo para escolher data
                VStack {
                    
                    // seleção da data
                    HStack {
                        Text("Data")
                            .font(.custom("SF Pro", size: 17, relativeTo: .title3))
                            .fontWeight(.medium)
                            .foregroundStyle(Color("primaryColor"))
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                isShowingPicker.toggle()
                            }
                        } label: {
                            Text(dateTask.formattedAsDayMonthAndHour())
                                .foregroundStyle(Color("backgroundTaskActivitySelected"))
                        }
                    }
                    
                    // picker
                    if isShowingPicker {
                        Divider()
                        DatePicker(
                            "",
                            selection: $dateTask,
                            in: Date()..., // Só permite datas futuras
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .tint(Color.yellow)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .transition(.opacity)
                    }
                }
                .hSpacing(.leading)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
            }
            
            // Mensagem de erro se houver
            //            if !canSave && titleTask == "Selecione" {
            //                Text("Selecione uma atividade para continuar")
            //                    .font(.caption)
            //                    .foregroundColor(.red)
            //                    .hSpacing(.leading)
            //            }
            
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
                .foregroundColor(canSave
                                 ? Color("primaryColor")
                                 : Color("primaryColor").opacity(0.4)
                )
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(canSave
                            ? Color("backgroundTaskButtonSave")
                            : Color("backgroundTaskButtonSave").opacity(0.4)
                )
                .cornerRadius(40)
            })
            .disabled(!canSave || isSaving)
            .padding(.bottom, 100)
        }
        .hSpacing(.leading)
        .vSpacing(.top)
        .padding()
        .background(Color("backgroundGenitor"))
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
