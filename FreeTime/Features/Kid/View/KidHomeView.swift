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
    @State private var showPopUp = false
    
    
    var body: some View {
        ZStack {
            Color(.defaultBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                HeaderView
                
                ScrollView(.vertical, showsIndicators: false) {
                        contentView

                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
                .refreshable {
                    print("KidHomeView: Pull to refresh...")
                    vmKid.refreshActivities()
                    
                }
            }
            .foregroundColor(.fontColorKid)
            .fontDesign(.rounded)
            .ignoresSafeArea()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("KidHomeView: Carregando na inicialização...")
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
                ZStack {
                    Color(.backgroundHeaderYellowKid)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView("Carregando...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .overlay{
            if showPopUp {
                VStack {
                    Spacer()
                    PopUp(showPopUp: $showPopUp)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
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
                        KidDataView(kidName: vmKid.kidName ?? "Carregando...", kidCoins: vmKid.kidCoins ?? 0)
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
        let notStarted = vmKid.notStartedRegister()
        let completed = vmKid.completedRegister()
        let allActivities = notStarted + completed
        
        return VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Atividades para hoje")
                    .kerning(0.4)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                
                Text(Date().formattedDayTitle())
                    .font(.title2)
                    .kerning(0.3)
            }
            
            if allActivities.isEmpty {
                Text("Hmm... parece que ainda não tem nada pra fazer agora. Que tal pedir pra um adulto adicionar uma atividade bem legal pra você?")
                    .padding(.trailing, 133)
                    .font(.title2)
                
            } else {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Para fazer")
                                .font(.title)
                                .kerning(0.38)
                                .fontWeight(.medium)
                            
                            if notStarted.isEmpty && !completed.isEmpty {
                                Text("Uhul! Você mandou super bem e completou tudo por hoje! Parabéns, você arrasou demais!")
                                    .padding(.trailing, 133)
                                    .font(.title2)
                                    .padding(.bottom, 62)
                            } else {
                                ActivitySection(
                                    registers: notStarted,
                                    emptyMessage: "",
                                    selectedRegister: $selectedRegister,
                                    vmKid: vmKid,
                                    showPopUp: $showPopUp
                                    
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
                            }
                            
                            Text("Feito")
                                .font(.title)
                                .kerning(0.38)
                                .fontWeight(.medium)
                            
                            if completed.isEmpty {
                                Text("Eita! Ainda não começamos nenhuma atividade hoje... Vamos entrar em ação?")
                                    .padding(.trailing, 133)
                                    .font(.title2)
                                
                            } else {
                                ActivitySection(
                                    registers: completed,
                                    emptyMessage: "",
                                    selectedRegister: $selectedRegister,
                                    vmKid: vmKid,
                                    showPopUp: $showPopUp
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 26)
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
    let kidName: String
    var kidCoins: Int
    
    var body: some View {
        HStack(spacing: 24) {
            Image(.iPerfil)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(kidName)
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                
                RoundedCorner(radius: 20)
                    .fill(.backgroundRoundedRectangleCoins)
                    .frame(width: 98, height: 35)
                    .overlay(alignment:.center){
                        HStack (spacing: 8){
                            Image(.iCoin)
                                .frame(width: 24, height: 24)
                            
                            Text("\(kidCoins)")
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
    @Binding var showPopUp: Bool
    
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
            DetailView(kidViewModel: vmKid, register: register,  onCompletion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showPopUp = true
                }
            })
        }
    }
}


#Preview {
    KidHomeView()
}
