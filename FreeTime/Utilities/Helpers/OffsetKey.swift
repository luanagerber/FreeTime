//
//  OffsetKey.swift
//  FreeTime
//
//  Created by Thales Araújo on 19/05/25.
//

import SwiftUI

struct OffsetKey: PreferenceKey {
    static var  defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
