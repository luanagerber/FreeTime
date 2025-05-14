//
//  KidViewModel.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 14/05/25.
//

import Foundation
import SwiftUI

class KidViewModel: ObservableObject {
    @Published var records: [Record] = Record.samples
}

