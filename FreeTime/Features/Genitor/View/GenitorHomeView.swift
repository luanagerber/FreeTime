//
//  GenitorHomeView.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

struct GenitorHomeView: View {
    
    @State private var currentTab: TabSelection = .activities
    
    var body: some View {
        TabView (selection: $currentTab){
            Tab(value: .activities) {
                GenitorCalendarView()
            } label: {
                Image(systemName: "calendar")
            }
            
            Tab("", systemImage: "cart", value: .rewards) {
                GenitorRewardsView()
            }
            
        }
        .tint(.mainGenitor)
    }
}

#Preview {
    GenitorHomeView()
}
