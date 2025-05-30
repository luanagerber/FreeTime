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
    case notCompleted = 0
    case completed = 2
    
    var color: Color {
        switch self {
            case .notCompleted: return .green.opacity(0.3)
            case .completed: return .gray.opacity(0.3)
        }
    }
}
