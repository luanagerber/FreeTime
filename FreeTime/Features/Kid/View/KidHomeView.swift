//
//  KidView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI
import CloudKit

struct KidHomeView: View {
    @State private var currentPage: Page = .kidHome
    @StateObject private var vmKid = KidViewModel()
    @State private var selectedRegister: ActivitiesRegister? = nil
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView
                contentView
            }
            .fontDesign(.rounded)
            .ignoresSafeArea()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("KidHomeView: Carregando na inicialização...")
            vmKid.refreshActivities()
        }
        .refreshable {
            print("KidHomeView: Pull to refresh...")
            vmKid.refreshActivities()
        }
        .alert("Erro", isPresented: $vmKid.showError) {
            Button("OK") {
                vmKid.clearError()
            }
        } message: {
            Text(vmKid.errorMessage)
        }
        .overlay {
            if vmKid.isLoading {
                ProgressView("Carregando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private var HeaderView: some View {
        Rectangle()
            .fill(.backgroundHeaderYellowKid)
            .cornerRadius(20)
            .frame(height: 156)
            .overlay {
                HStack {
                    HStack(spacing: 24) {
                        // ✅ CORREÇÃO: Usar dados reais do vmKid
                        KidDataView(kid: vmKid.kid ?? Kid(name: "Carregando...", coins: vmKid.kidCoins ?? 0))
                            .padding(.top, 46)
                            .ignoresSafeArea()
                            .frame(maxHeight: 156, alignment: .top)
                    }
                    Spacer()
                    HStack(spacing: 39) {
                        NavButton(page: .kidHome, icon: .iActivity)
                        NavButton(page: .rewardsStore, icon: .iStore)
                    }
                    .padding(.bottom, 15)
                    .ignoresSafeArea()
                    .frame(maxHeight: 156, alignment: .bottom)
                }
                .ignoresSafeArea()
                .frame(maxHeight: 156)
                .padding(.horizontal, 36)
                .foregroundColor(.fontColorKid)
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch currentPage {
            case .kidHome:
                ActivitiesView
            case .rewardsStore:
                RewardsStoreView(store: coordinator.rewardsStore)
            default:
                EmptyView()
        }
    }

    private var ActivitiesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Atividades para hoje")
                    .kerning(0.4)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(Date().formattedDayTitle())
                    .font(.title2)
                    .kerning(0.3)
            }
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Para fazer")
                            .font(.title)
                            .kerning(0.38)
                            .fontWeight(.medium)
                        
                        // ✅ CORREÇÃO: Usar dados reais do ViewModel
                        ActivitySection(
                            registers: vmKid.notStartedRegister(),
                            emptyMessage: "Não há atividades a serem realizadas hoje.",
                            selectedRegister: $selectedRegister,
                            vmKid: vmKid
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
                        
                        Text("Feito")
                            .font(.title)
                            .kerning(0.38)
                            .fontWeight(.medium)
                        
                        // ✅ CORREÇÃO: Usar dados reais do ViewModel
                        ActivitySection(
                            registers: vmKid.completedRegister(),
                            emptyMessage: "Nenhuma atividade concluída hoje.",
                            selectedRegister: $selectedRegister,
                            vmKid: vmKid
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.leading, 133)
    }
    
    private func NavButton(page: Page, icon: ImageResource) -> some View {
        let isSelected = currentPage == page
        return Button {
            currentPage = page
        } label: {
            VStack {
                Image(icon)
                    .frame(width: 137, height: 146)
                    .opacity(isSelected ? 1 : 0.5)
            }
        }
        .disabled(isSelected)
    }
}

struct KidDataView: View {
    let kid: Kid
    
    var body: some View {
        HStack(spacing: 24) {
            Image(.iPerfil)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(kid.name)
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                
                RoundedCorner(radius: 20)
                    .fill(.backgroundRoundedRectangleCoins)
                    .frame(width: 98, height: 35)
                    .overlay(alignment:.center){
                        HStack (spacing: 8){
                            Image(.iCoin)
                                .frame(width: 24, height: 24)
                            
                            Text("\(kid.coins)")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                        }
                    }
            }
            .frame(maxHeight: 80, alignment: .bottom)
            
        }
    }
}

struct ActivitySection: View {
    let registers: [ActivitiesRegister]
    let emptyMessage: String
    @Binding var selectedRegister: ActivitiesRegister?
    var vmKid: KidViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if registers.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(registers) { register in
                            Button {
                                selectedRegister = register
                            } label: {
                                CardActivity(register: register)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedRegister) { register in
            DetailView(kidViewModel: vmKid, register: register)
        }
    }
}


#Preview {
    KidHomeView()
}
