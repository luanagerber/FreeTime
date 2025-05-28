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
        
        /// 1º forma
        //        TabView (selection: $currentTab){
        //            Tab(value: .activities) {
        //                GenitorCalendarView()
        //            } label: {
        //                VStack {
        //                    Image(systemName: "calendar")
        //                }
        //
        //            }
        //
        //            Tab(value: .addActivity) {
        //
        //            } label: {
        //                VStack() {
        //                    Image(systemName: "plus.circle.fill")
        //                }
        //                Button(action: {
        //                    viewModel.createNewTask.toggle()
        //                    print("hello")
        //                },label: {
        //                    Image(systemName: "plus.circle.fill")
        //                })
        //            }
        //
        //            Tab(value: .rewards) {
        //                GenitorRewardsView()
        //            } label: {
        //                Image(systemName: "cart")
        //            }
        //        }
        //        .tint(.mainGenitor)
        //        .onChange(of: currentTab) {
        //            print("Aba ativa: \(currentTab)")
        //        }
        //        .sheet(isPresented: $viewModel.createNewTask, content: {
        //            NewTaskView()
        //        })
        
        /// 2º forma
        //        ZStack {
        //            TabView(selection: $currentTab) {
        //                GenitorCalendarView()
        //                    .tabItem {
        //                        Image(systemName: "calendar")
        //                    }
        //                    .tag(TabSelection.activities)
        //
        //                GenitorRewardsView()
        //                    .tabItem {
        //                        VStack {
        //                            Image(systemName: "cart")
        //                            if (currentTab == .rewards) {
        //                                Rectangle()
        //                                    .fill(Color.mainGenitor)
        //                                    .cornerRadius(50)
        //                                    .frame(width: 2, height: 2, alignment: .center)
        //                                    .padding(.horizontal, 20)
        //                            }
        //
        //                        }
        //
        //                    }
        //                    .tag(TabSelection.rewards)
        //            }
        //            .tint(Color.mainGenitor)
        //
        //            VStack {
        //                Spacer()
        //
        //                HStack {
        //                    Spacer()
        //
        //                    Button(action: {
        //                        viewModel.createNewTask.toggle()
        //                    }) {
        //                        Image(systemName: "plus")
        //                            .font(.system(size: 28, weight: .bold))
        //                            .foregroundColor(.white)
        //                            .padding()
        //                            .background(Color.mainGenitor)
        //                            .clipShape(Circle())
        //                            .shadow(radius: 4)
        //                    }
        //                    //.offset(y: -10)
        //                    .padding(.bottom, 10)
        //
        //                    Spacer()
        //                }
        //            }
        //        }
        //        .sheet(isPresented: $viewModel.createNewTask) {
        //            NewTaskView()
        //        }
        
        ///3º forma
        ZStack {
            // Conteúdo principal
            Group {
                switch currentTab {
                case .activities:
                    GenitorCalendarView()
                case .rewards:
                    GenitorRewardsView()
                }
                
                VStack {
                    Spacer()
                    
                    CustomTabBar()
                        .ignoresSafeArea(edges: .bottom)
                }
                
            }
            .sheet(isPresented: $viewModel.createNewTask) {
                NewTaskView()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        
        
    }
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 60) {
            TabBarItem(icon: "calendar", tab: .activities)
            
            Button(action: {
                viewModel.createNewTask = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.mainGenitor))
                    //.shadow(radius: 4)
            }
            .offset(y: -10)
            
            TabBarItem(icon: "cart", tab: .rewards)
        }
        .padding(.vertical, 19)
        .padding(.horizontal, 24)
        .background(Color.white)
        //.clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    @ViewBuilder
    func TabBarItem(icon: String, tab: TabSelection) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(currentTab == tab ? .mainGenitor : .gray)
            
            // barrinha inferior se estiver ativo
            Capsule()
                .fill(currentTab == tab ? Color.mainGenitor : Color.clear)
                .frame(width: 24, height: 3)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle()) // permite clicar em toda a área
        .onTapGesture {
            currentTab = tab
        }
    }
    
    
}

#Preview {
    GenitorHomeView()
}
