//
//  RegisterStatus.swift
//  FreeTime
//
//  Created by Luana Gerber on 21/05/25.
//

import Foundation
import SwiftUI

// @ Alterado para integrar o CloudKit
enum RegisterStatus: Int {
    case notStarted = 0
    case inProgress = 1
    case completed = 2
    
    var color: Color {
        switch self {
            case .notStarted: return .green.opacity(0.3)
            case .inProgress: return .yellow
            case .completed: return .gray.opacity(0.3)
        }
    }
}
