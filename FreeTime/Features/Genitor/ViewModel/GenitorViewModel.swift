//
//  ParentViewModel.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import SwiftUI

class GenitorViewModel: ObservableObject {
    @Published var records: [Record] = Record.samples 
}
