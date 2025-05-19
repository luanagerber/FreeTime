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
    private var cloudService: CloudService = .shared
    
    @Published var records: [Register] = Register.samples
//    @Published var recordsCloudKit: [Register] = []
    @Published var selectedDate = Date()
    
//    func fetchRecords() -> [Register] {
//        
//    }
}
