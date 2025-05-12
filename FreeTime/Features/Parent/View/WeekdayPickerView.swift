import SwiftUI

struct WeekdayPickerView: View {
    @State private var selectedDate = Date()
    @State var daysDisplayedOnCalendar: Int = 21
    @State var isSelected: Bool = false
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.dateInterval(of: .day, for: today)?.start else {
            return []
        }
        return (0..<21).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }
    
    @ViewBuilder
    func dayWeekCircleView(date: Date, selectedDate: Date) -> some View {
        VStack {
            Text(date.formatted(.dateTime.weekday(.short)))
            Text(date.formatted(.dateTime.day()))
        }
        .padding(10)
        .background(date == selectedDate ? .green : .black)
        .opacity(0.9)
        .clipShape(.capsule(style: .continuous))
        
        
        .foregroundColor(.white)
    }
    
    var body: some View {
        VStack(spacing: 30){
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    ForEach(weekDates, id: \.self) { date in
                        
                        Button(action: {
                            isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            selectedDate = date
                        }) {
                            
                           dayWeekCircleView(date: date, selectedDate: selectedDate)
                                .containerRelativeFrame(.horizontal, count: 7, spacing: 10)
                            
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(16, for: .scrollIndicators)
            .scrollTargetBehavior(.paging)
            
            
            // Optional: hora separada
            DatePicker("Hora", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            Text(selectedDate.description)
        }
    }
}

#Preview {
    WeekdayPickerView(daysDisplayedOnCalendar: 14)
    
}
