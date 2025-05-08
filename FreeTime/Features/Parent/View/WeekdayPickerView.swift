import SwiftUI

struct WeekdayPickerView: View {
    @State private var selectedDate = Date()
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        return (0..<21).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }
    
    var body: some View {
        VStack(spacing: 30){
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weekDates, id: \.self) { date in
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        Button(action: {
                            selectedDate = date
                        }) {
                            VStack {
                                Text(date.formatted(.dateTime.weekday(.short)))
                                Text(date.formatted(.dateTime.day()))
                            }
                            .padding(10)
                            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(isSelected ? .white : .primary)
                        }
                    }
                }
                .padding()
            }
            
            // Optional: hora separada
            DatePicker("Hora", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            Text(selectedDate.description)
        }
    }
}

#Preview {
    WeekdayPickerView()
}
