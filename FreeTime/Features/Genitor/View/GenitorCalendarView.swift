//
//  GenitorCalendarView.swift
//  FreeTime
//
//  Created by Thales Araújo on 19/05/25.
//
import SwiftUI

#warning("Violação do Princípio de Responsabilidade Única do SOLID. O arquivo contém lógica de UI, carregamento de dados e estados")

#warning("Para um arquivo com número ostensivo de linhas, o ideal é subdividir em outros arquivos. Exemplo: HeaderView, WeekView, TasksView, etc. Sugestão: Deixar a view principal apenas como 'orquestradora'.")

struct GenitorCalendarView: View {
    
    /// Task Manager Properties
    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false

    #warning("Problemas de clareza: o dev pode assumir que esse objeto muda a cada instância da view, mas na verdade é sempre o mesmo. Se a utilização for devido a reatividade, prefira usar '@ObservedObject private var genitorViewModel = GenitorViewModel.shared'")
    
    @StateObject var viewModel = GenitorViewModel()

    /// Animation Namespace
    @Namespace private var animation

    var body: some View {
        VStack(){
            
            // Calendário
            HeaderView()
            
            // Tarefas
            ScrollView(.vertical) {
                VStack {
                    TasksView()
                        .padding()
                }
                .hSpacing(.center)
                .vSpacing(.center)
            }
            .scrollIndicators(.hidden)
            #warning("Criar um Color Set na pasta de assets e chamar no background, mais seguro para não errar o nome da cor")
        }
        .background(Color(.backgroundGenitor))
        .vSpacing(.top)
        
        .onAppear {
        #warning("Muita coisa sendo executada no onAppear. Sugestão: Separar em um método em um serviço ou na viewmodel.")
            viewModel.setupCloudKit()
            
            if weekSlider.isEmpty {
                let currentWeek = Date().fetchWeek()
                
                if let firstDate = currentWeek.first?.date {
                    weekSlider.append(firstDate.createPrevisousWeek())
                }
                
                weekSlider.append(currentWeek)
                
                if let lastDate = currentWeek.last?.date {
                    weekSlider.append(lastDate.createNextWeek())
                }
            }
            
            // Carrega atividades inicialmente
            loadActivitiesForCurrentDate()
        }
        .refreshable {
            viewModel.refresh()
            loadActivitiesForCurrentDate()
        }
        .sheet(isPresented: $viewModel.showActivitySelector) {
            ActivitySelectorView()
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack (alignment: .leading) {
            #warning("Sugestão: extension de Font, para não precisar passar o nome da fonte customizada toda vez que for aplicá-la em uma view.")
            
            Text(viewModel.currentDate.formattedMonthUppercase())
                .font(.custom("SF Pro", size: 34, relativeTo: .largeTitle))
                .fontWeight(.semibold)
                .foregroundStyle(Color("primaryColor"))
            
            // Semana
            TabView(selection: $currentWeekIndex) {
                ForEach(weekSlider.indices , id: \.self) { index in
                    let week = weekSlider[index]
                    WeekView(week)
                        .padding(.horizontal, 15)
                        .tag(index)
                }
            }
            .padding(.horizontal, -15)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.height*0.08)
        }
        .hSpacing(.leading)
        .padding(15)
        .background(
            Color("backgroundCalendarHeader")
                .cornerRadius(Constants.UI.cardCornerRadius, corners: [.bottomLeft, .bottomRight])
                .ignoresSafeArea(edges: .top)
                .shadow(radius: 5)
        )
        .onChange(of: currentWeekIndex, initial: false) { oldValue, newValue in
            /// Creating when it reaches first/last page
            if newValue == 0 || newValue == (weekSlider.count - 1) {
                createWeek = true
            }
        }
    }
    
    @ViewBuilder
    func WeekView(_ week: [Date.WeekDay]) -> some View {
        
        HStack(spacing: 0) {
            
            // Iterando sobre a semana
            ForEach(week) { day in
                
                // Visualização do dia
                VStack(){
                    Text(day.date.format("E"))
                        .font(.custom("SF Pro", size: 13, relativeTo: .footnote))
                        .textScale(.secondary)
                        .foregroundStyle(Color("primaryColor"))
                    
                    Rectangle()
                        .fill(Color("primaryColor"))
                        .cornerRadius(50)
                        .frame(height: UIScreen.main.bounds.height*0.002)
                        .padding(.horizontal, 16)
                    
                    Text(day.date.format("dd"))
                        .font(.custom("SF Pro", size: 17, relativeTo: .body))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("primaryColor"))
                }
                .hSpacing(.center)
                .contentShape(.rect)
                .onTapGesture {
                    // Updating current date
                    withAnimation(.snappy) {
                        viewModel.currentDate = day.date
                        loadActivitiesForCurrentDate()
                    }
                }
                .background {
                    if isSameDate(day.date, viewModel.currentDate) {
                        #warning("Cuidado com a utilização de magic numbers...@ScaledMetrics")
                        Rectangle()
                            .foregroundColor(Color("backgroundCalendarSelectedDay"))
                            .frame(width: 46, height: 68)
                            .background(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .background {
            GeometryReader {
                let minX = $0.frame(in: .global).minX
                
                Color.clear
                    .preference(key: CalendarOffsetKey.self, value: minX)
                    .onPreferenceChange(CalendarOffsetKey.self) { value in
                        /// When the offset reaches 15 and and if the createWeek is toggled then simply generating next set of weak
                        if value.rounded() == 15 && createWeek {
                            paginateWeek()
                            createWeek = false
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func TasksView() -> some View {
        
        VStack(alignment: .center, spacing: 20) {
    
            #warning("Evitar lógica pesada dentro de views. Sugestão: Colocar em um serviço ou manager.")
            // CORREÇÃO: Filtrar atividades do dia selecionado, não apenas "hoje"
            let tasksNotStarted = viewModel.records.filter { register in
                Calendar.current.isDate(register.date, inSameDayAs: viewModel.currentDate) &&
                register.registerStatus == .notCompleted
            }.sorted(by: { $0.date < $1.date})
            
            let tasksCompleted = viewModel.records.filter { register in
                Calendar.current.isDate(register.date, inSameDayAs: viewModel.currentDate) &&
                register.registerStatus == .completed
            }.sorted(by: { $0.date < $1.date})
            
            // Atividade Planejadas
            Text("Atividades planejadas")
                .font(.custom("SF Pro", size: 20, relativeTo: .title3))
                .fontWeight(.medium)
                .foregroundStyle(Color("primaryColor"))
                .hSpacing(.leading)
            
            if (tasksCompleted.isEmpty && tasksNotStarted.isEmpty) {
                VStack(spacing: 16) {
                    Text("Nenhuma atividade foi planejada ainda. Clique em \"+\" para começar!")
                        .font(.subheadline)
                        .foregroundStyle(Color("primaryColor"))
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                
                if tasksNotStarted.isEmpty {
                    Text("Tudo concluído para esse dia! Ótimo trabalho em equipe!")
                        .font(.subheadline)
                        .foregroundStyle(Color("primaryColor"))
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                } else {
                    ForEach(tasksNotStarted) { record in
                        GenitorTaskRowView(record: record)
                    }
                }
                
                Spacer(minLength: 14)
                
                
                // Atividades concluídas
                Text("Atividades concluídas")
                    .font(.custom("SF Pro", size: 20, relativeTo: .title3))
                    .fontWeight(.medium)
                    .foregroundStyle(Color("primaryColor"))
                    .hSpacing(.leading)
                
                if tasksCompleted.isEmpty {
                    Text("Nada foi concluído nesse dia ainda. Que tal checar com seu filho?")
                        .font(.subheadline)
                        .foregroundStyle(Color("primaryColor"))
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                } else {
                    ForEach(tasksCompleted) { record in
                        GenitorTaskRowView(record: record)
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    func ActivitySelectorView() -> some View {
        NavigationView {
            VStack {
                // Activity list
                List(Activity.catalog, id: \.id) { activity in
                    Button(action: {
                        viewModel.selectedActivity = activity
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(activity.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if viewModel.selectedActivity?.id == activity.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Date and duration selectors
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("Data e hora", selection: $viewModel.scheduledDate)
                        .datePickerStyle(.compact)
                    
                    Picker("Duração", selection: $viewModel.duration) {
                        Text("30 minutos").tag(TimeInterval(1800))
                        Text("1 hora").tag(TimeInterval(3600))
                        Text("1 hora e 30 minutos").tag(TimeInterval(5400))
                        Text("2 horas").tag(TimeInterval(7200))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("Nova Atividade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        viewModel.showActivitySelector = false
                        viewModel.selectedActivity = nil
                    }
                }
            }
        }
    }
    
    func paginateWeek() {
        /// SafeCheck
        if weekSlider.indices.contains(currentWeekIndex) {
            if let firstData = weekSlider[currentWeekIndex].first?.date, currentWeekIndex == 0 {
                ///  Inserting new week at 0th index and removing last array item
                weekSlider.insert(firstData.createPrevisousWeek(), at: 0)
                weekSlider.removeLast()
                currentWeekIndex = 1
                viewModel.currentDate = Calendar.current.date(byAdding: .day, value: -7, to: viewModel.currentDate) ?? viewModel.currentDate
            }
            
            if let lastData = weekSlider[currentWeekIndex].last?.date, currentWeekIndex == (weekSlider.count - 1) {
                ///  Inserting new week at last index and removing first array item
                weekSlider.append(lastData.createNextWeek())
                weekSlider.removeFirst()
                currentWeekIndex = weekSlider.count - 2
                viewModel.currentDate = Calendar.current.date(byAdding: .day, value: 7, to: viewModel.currentDate) ?? viewModel.currentDate
            }
        }
    }
    
    // CORREÇÃO: Carregar todas as atividades, não apenas filtrar por horário
    private func loadActivitiesForCurrentDate() {
        guard let kidID = viewModel.firstKid?.id?.recordName else { return }
        
        CloudService.shared.fetchAllActivities(forKid: kidID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let activities):
                    // Carregar TODAS as atividades, deixar o filtro para a TasksView
                    viewModel.records = activities
                    print("🔍 GenitorCalendarView: Carregadas \(activities.count) atividades totais")
                    
                    // Debug: Mostrar quais atividades são para a data selecionada
                    let activitiesForSelectedDate = activities.filter { activity in
                        Calendar.current.isDate(activity.date, inSameDayAs: viewModel.currentDate)
                    }
                    print("🔍 GenitorCalendarView: \(activitiesForSelectedDate.count) atividades para \(viewModel.currentDate)")
                    
                case .failure(let error):
                    print("Erro ao carregar atividades: \(error)")
                }
            }
        }
    }
}

// MARK: - Offset Key for Week Pagination (renamed to avoid conflicts)
private struct CalendarOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    GenitorCalendarView()
}
