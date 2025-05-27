//
//  Date+Extensions.swift
//  FreeTime
//
//  Created by Thales Araújo on 19/05/25.
//

import SwiftUI

extension Date {
    struct WeekDay: Identifiable {
        var id: UUID = .init()
        var date: Date
    }
    
    static func updateHour(_ value: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .hour, value: value, to: .init()) ?? .init()
    }
    
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
    
    /// Checking wheter the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checking if the date is same hour
    var isSameHour: Bool {
        return Calendar.current.compare(self, to: .init(), toGranularity: .hour) == .orderedSame
    }
    
    /// Checking if the date is past hours
    var isPast: Bool {
        return Calendar.current.compare(self, to: .init(), toGranularity: .hour) == .orderedAscending
    }
    
    /// Fetching Week Based on given Date
    func fetchWeek(_ date: Date = .init()) -> [WeekDay] {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        
        var week: [WeekDay] = []
        
        // Retorna a semana que contém o startOfDate, ou seja, um vetor de [Date]
        let weekForDate = calendar.dateInterval(of: .weekOfMonth, for: startOfDate)
        
        // Retorna o primeiro dia da semana
        guard let startOfWeek = weekForDate?.start else { return [] }
        
        // Iteração para obter a semana inteira
        (0...6).forEach { index in
            if let weekDay = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                week.append(.init(date: weekDay))
            }
            
        }
        
        return week
    }
    
    /// Creating Next Week, based on the Last Current Week's  Date
    func createNextWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let startOfLastDate = calendar.startOfDay(for: self)
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: startOfLastDate) else { return []  }
        
        return fetchWeek(nextDate)
    }
    
    /// Creating Previous Week, based on the First Current Week's  Date
    func createPrevisousWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let startOfFirstDate = calendar.startOfDay(for: self)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: startOfFirstDate) else { return []  }
        
        return fetchWeek(previousDate)
    }
    
    /// functions created by Bia
    func formattedDayTitle(locale: Locale = Locale(identifier: "pt_BR")) -> String {
        let weekday = self.formatted(.dateTime.weekday(.wide).locale(locale)).capitalized
        let date = self.formatted(.dateTime.day().month(.wide).locale(locale))
        return "\(weekday) | \(date)"
    }
    
    func timeRange(duration: TimeInterval, format: String = "HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let endDate = self.addingTimeInterval(duration)
        return "\(formatter.string(from: self)) - \(formatter.string(from: endDate))"
    }
    
    /// Formata a data para exibir o dia da semana abreviado, dia do mês e mês abreviado (ex: "Qua. 21 de mai.").
    func formattedAsDayMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR") // Define o idioma para o português do Brasil
        formatter.dateFormat = "EEE dd 'de' MMM" // Formato como "Qua. 21 de mai."
        return formatter.string(from: self)
    }
    
    /// Retorna a data no início do dia, útil para agrupar recompensas que ocorreram no mesmo dia.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
