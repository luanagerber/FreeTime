//
//  GenitorHomeView.swift
//  FreeTime
//
//  Created by Thales Araújo on 26/05/25.
//

import SwiftUI

struct GenitorHomeView: View {
    
    @State private var currentTab: TabSelection = .activities
    @StateObject var viewModel = GenitorViewModel.shared
    
    var body: some View {
        TabView (selection: $currentTab){
            Tab(value: .activities) {
                GenitorCalendarView()
            } label: {
                VStack {
                    Image(systemName: "calendar")
                }
                
            }
            
            Tab(value: .addActivity) {
                
            } label: {
                VStack() {
                    Image(systemName: "plus.circle.fill")
                }
                Button(action: {
                    viewModel.createNewTask.toggle()
                    print("hello")
                },label: {
                    Image(systemName: "plus.circle.fill")
                })
            }
            
            Tab(value: .rewards) {
                GenitorRewardsView()
            } label: {
                Image(systemName: "cart")
            }
        }
        .tint(.mainGenitor)
        .onChange(of: currentTab) {
            print("Aba ativa: \(currentTab)")
        }
        .sheet(isPresented: $viewModel.createNewTask, content: {
            NewTaskView()
        })
    }
}

#Preview {
    GenitorHomeView()
}
