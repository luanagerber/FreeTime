import SwiftUI

struct GenitorCalendarView: View {
    
    @StateObject var viewModel = GenitorViewModel.shared
    
    // Gera os dias da semana com base na data selecionada
    private var weekDates: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: viewModel.selectedDate) else {
            return []
        }
        return (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    // Formatação para o nome do dia (dom, seg, ter, ...)
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()
    
    // Formatação para o número do dia (11, 12, 13...)
    private let numberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()
    
    // Formatação para mês e ano
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM 'de' yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()
    
    var body: some View {
        VStack {
            // Mês e ano no topo
            Text(monthYearFormatter.string(from: viewModel.selectedDate))
                .font(.largeTitle)
                .bold()
                .padding()
                .foregroundColor(.green)
            
            // Scroll horizontal dos dias da semana
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: 8) {
                            Text(dayFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(numberFormatter.string(from: date))
                                .font(.title3)
                                .bold()
                                .foregroundColor(isSameDay(date1: date, date2: viewModel.selectedDate) ? .white : .primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isSameDay(date1: date, date2: viewModel.selectedDate) ? Color.green : Color.clear)
                                )
                        }
                        .onTapGesture {
                            viewModel.selectedDate = date
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .contentMargins(16, for: .scrollIndicators)
            .scrollTargetBehavior(.paging)
        }
    }
    
    // Função para comparar se duas datas são o mesmo dia
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}

#Preview {
    GenitorCalendarView()
}
