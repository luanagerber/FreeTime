//
//  GenitorCalendarView.swift
//  FreeTime
//
//  Created by Thales Araújo on 19/05/25.
//
import SwiftUI

struct GenitorCalendarView: View {
    
    /// Task Manager Properties
    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false
    @StateObject var viewModel = GenitorViewModel.shared
    
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
            
        }
        .vSpacing(.top)
        .onAppear {
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
            
            HStack {
                // Mês
                Text(viewModel.currentDate.format("MMMM"))
                    .font(.custom("SF Pro", size: 34, relativeTo: .largeTitle))
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Botão para adicionar atividade
                Button(action: {
                    if !viewModel.kids.isEmpty {
                        viewModel.selectedKid = viewModel.firstKid
                        viewModel.showActivitySelector = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.kids.isEmpty)
            }
            
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
            .frame(height: 90)
        }
        .hSpacing(.leading)
        .padding(15)
        .background(
                Color.backgroundHeader
                    .cornerRadius(Constants.UI.cardCornerRadius, corners: [.bottomLeft, .bottomRight])
                    .ignoresSafeArea(edges: .top)
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
                        .fontWeight(.medium)
                        .textScale(.secondary)
                        .foregroundStyle(.gray)
                    
                    Rectangle()
                        .fill(.gray)
                        .cornerRadius(50)
                        .frame(height: 2)
                        .padding(.horizontal, 20)
                    
                    Text(day.date.format("dd"))
                        .font(.custom("SF Pro", size: 17, relativeTo: .body))
                        .fontWeight(.semibold)
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
                        Rectangle()
                            .foregroundColor(.white)
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
            
            let tasksNotStarted = viewModel.records.filter { register in
                Calendar.current.isDate(register.date, inSameDayAs: viewModel.currentDate) &&
                register.registerStatus == .notStarted
            }.sorted(by: { $1.date > $0.date})
            
            let tasksCompleted = viewModel.records.filter{ register in
                Calendar.current.isDate(register.date, inSameDayAs: viewModel.currentDate) &&
                register.registerStatus == .completed
            }.sorted(by: { $1.date > $0.date})
            
            // Atividade Planejadas
            Text("Atividades planejadas")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if (tasksCompleted.isEmpty && tasksNotStarted.isEmpty) {
                VStack(spacing: 16) {
                    Text("Nenhuma atividade foi planejada ainda.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    if !viewModel.kids.isEmpty {
                        Button("Adicionar Atividade") {
                            viewModel.selectedKid = viewModel.firstKid
                            viewModel.showActivitySelector = true
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Adicione uma criança primeiro para planejar atividades.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                
                if tasksNotStarted.isEmpty {
                    Text("Tudo concluído por hoje! Ótimo trabalho em equipe!")
                        .padding(.horizontal)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(tasksNotStarted) { record in
                        GenitorTaskRowView(record: record)
                    }
                }
                
                Spacer(minLength: 14)
                
                
                // Atividades concluídas
                Text("Atividades concluídas")
                    .font(.title3)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if tasksCompleted.isEmpty {
                    Text("Nada foi concluído hoje ainda. Que tal checar com seu filho?")
                        .padding(.horizontal)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                
                // Schedule button
                Button("Agendar Atividade") {
                    viewModel.scheduleActivity()
                    loadActivitiesForCurrentDate()
                }
                .disabled(viewModel.selectedActivity == nil || viewModel.selectedKid == nil || viewModel.isLoading)
                .padding()
                .background(viewModel.selectedActivity != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
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
    
    private func loadActivitiesForCurrentDate() {
        guard let kidID = viewModel.firstKid?.id?.recordName else { return }
        
        CloudService.shared.fetchAllActivities(forKid: kidID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let activities):
                    viewModel.records = activities
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
