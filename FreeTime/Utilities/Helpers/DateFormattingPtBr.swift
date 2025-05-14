//
//  DateFormattingPtBr.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation

extension Date {
    func formattedDayTitle(locale: Locale = Locale(identifier: "pt_BR")) -> String {
        let weekday = self.formatted(.dateTime.weekday(.wide).locale(locale)).capitalized
        let date = self.formatted(.dateTime.day().month(.wide).locale(locale))
        return "\(weekday) | \(date)"
    }
}
