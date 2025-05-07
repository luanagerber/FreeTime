//
//  RecordViewModel.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 07/05/25.
//

import SwiftUI

class RecordViewModel: ObservableObject {
    
    @Published var records: [Record] = []
    
    init() {
        self.records = [.sample1, .sample2, .sample1, .sample2]
    }
    
}
