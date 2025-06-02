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
            // ✅ CORREÇÃO: Sheet moved to the correct level
            .sheet(isPresented: $viewModel.createNewTask) {
                NewTaskView()
                    .presentationDetents([.large]) // Alturas suportadas
                    .presentationDragIndicator(.visible)   // Mostra o indicador de arraste
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 60) {
            TabBarItem(icon: "calendar", tab: .activities)
            
            // ✅ CORREÇÃO: Este botão deve abrir NewTaskView
            Button(action: {
                print("🔘 GenitorHomeView: Botão + pressionado")
                viewModel.createNewTask = true
                print("✅ GenitorHomeView: createNewTask = \(viewModel.createNewTask)")
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color("primaryColor")))
            }
            .offset(y: -10)
            
            TabBarItem(icon: "cart", tab: .rewards)
        }
        .padding(.vertical, 19)
        .padding(.horizontal, 24)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    @ViewBuilder
    func TabBarItem(icon: String, tab: TabSelection) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.custom("SF Pro", size: 22, relativeTo: .body))
                .foregroundColor(currentTab == tab ? Color("primaryColor") : Color("primaryColor").opacity(0.4))
            
            // barrinha inferior se estiver ativo
            Capsule()
                .fill(currentTab == tab ? Color("primaryColor") : Color.clear)
                .frame(width: UIScreen.main.bounds.width*0.06, height: UIScreen.main.bounds.height*0.004)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle()) // permite clicar em toda a área
        .onTapGesture {
            print("🔘 TabBarItem clicado: \(tab)")
            withAnimation(.easeInOut(duration: 0.2)) {
                currentTab = tab
            }
            print("✅ currentTab agora é: \(currentTab)")
        }
    }
}

#Preview {
    GenitorHomeView()
}
