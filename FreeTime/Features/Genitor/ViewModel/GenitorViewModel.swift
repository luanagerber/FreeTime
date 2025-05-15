//
//  ParentViewModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

class GenitorViewModel: ObservableObject {
    
    static let shared = GenitorViewModel()
    
    @Published var records: [Register] = Register.samples
    @Published var selectedDate = Date()
}
