//
//  GenitorHomeView.swift
//  FreeTime
//
//  Created by Thales Araújo on 19/05/25.
//

import SwiftUI

struct GenitorHomeView: View {
    
    /// Task Manager Properties
    @State private var currentDate: Date = .init()
    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false
    //    @State private var tasks: [Task] = sampleTasks.sorted(by: { $1.creationDate > $0.creationDate})
    @State private var createNewTask: Bool = false
    
    /// Animation Namespace
    @Namespace private var animation
    
    /// View Model
    @StateObject var viewModel = GenitorViewModel.shared
    
    var body: some View {
        VStack(){
            HeaderView()
            
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
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack (alignment: .leading) {
            
            // Mês
            Text(currentDate.format("MMMM"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            
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
        .background(.backgroundHeader)
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
                        .font(.footnote)
                        .fontWeight(.medium)
                        .textScale(.secondary)
                        .foregroundStyle(.gray)
                    
                    Rectangle()
                        .fill(.gray)
                        .cornerRadius(50)
                        .frame(height: 2)
                        .padding(.horizontal, 20)
                    
                    Text(day.date.format("dd"))
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .hSpacing(.center)
                .contentShape(.rect)
                .onTapGesture {
                    // Updating current date
                    withAnimation(.snappy) {
                        currentDate = day.date
                    }
                }
                .background {
                    if isSameDate(day.date, currentDate) {
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
                    .preference(key: OffsetKey.self, value: minX)
                    .onPreferenceChange(OffsetKey.self) { value in
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
            
            // Atividade Planejadas
            Text("Atividades planejadas")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            let tasksNotStarted = viewModel.records.filter({$0.registerStatus == .notStarted})
            
            if tasksNotStarted.isEmpty {
                Text("Nenhuma atividade foi planejada ainda. Clique em \"+\" para começar!")
                    .padding(.horizontal)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                
            } else {
                ForEach(tasksNotStarted) { record in
                    TaskRowView(record: record)
                }
            }
            
            Spacer(minLength: 14)
            
            // Atividades concluídas
            Text("Atividades concluídas")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            let tasksCompleted = viewModel.records.filter({$0.registerStatus == .completed})
            
            if tasksCompleted.isEmpty {
                Text("Nada foi concluído hoje ainda. Que tal checar com seu filho?")
                    .padding(.horizontal)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(tasksCompleted) { record in
                    TaskRowView(record: record)
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
            }
            
            if let lastData = weekSlider[currentWeekIndex].last?.date, currentWeekIndex == (weekSlider.count - 1) {
                ///  Inserting new week at last index and removing first array item
                weekSlider.append(lastData.createNextWeek())
                weekSlider.removeFirst()
                currentWeekIndex = weekSlider.count - 2
            }
        }
    }
}

#Preview {
    GenitorHomeView()
}
