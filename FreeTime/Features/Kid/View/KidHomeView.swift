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
    @StateObject var vmKid : KidViewModel
    @State private var selectedRegister: ActivitiesRegister? = nil
    @EnvironmentObject var coordinator: Coordinator
    @State private var messageCompletedActivy : Bool = false
    
    
    var body: some View {
        ZStack {
            Color(.defaultBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                HeaderView
                
                ScrollView(.vertical, showsIndicators: false) {
                        contentView

                    .frame(maxWidth: .infinity)
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
//                ZStack {
//                    Color(.backgroundHeaderYellowKid)
//                        .ignoresSafeArea()
//                    VStack(spacing: 16) {
//                        ProgressView("Carregando...")
//                            .progressViewStyle(CircularProgressViewStyle(tint: .fontColorKid))
//                            .foregroundColor(.fontColorKid)
//                            .font(.title)
//                            .fontWeight(.bold)
//                    }
//                }
//                .transition(.opacity)
//                .zIndex(2)
            .overlay {
                HStack {
                        KidDataView(kidName: vmKid.kidName ?? "Carregando...", kidCoins: vmKid.kidCoins)
                            .padding(.top, 46)
                            .ignoresSafeArea()
                            .frame(maxHeight: 156, alignment: .top)
                    }
                    Spacer()
                    HStack(spacing: 39) {
                        NavButton(page: .kidHome)
                        NavButton(page: .rewardsStore)
                    }
                    .padding(.bottom, 15)
                        KidDataView(kidName: vmKid.kidName ?? "Carregando...", kidCoins: vmKid.kidCoins)
                    .frame(maxHeight: 156, alignment: .bottom)
                }
                .ignoresSafeArea()
                .frame(maxHeight: 156)
                .padding(.horizontal, 36)
                .foregroundColor(.fontColorKid)
                        NavButton(page: .kidHome, icon: .iActivity)
                        NavButton(page: .rewardsStore, icon: .iStore)
    
    @ViewBuilder
    private var contentView: some View {
        switch currentPage {
            case .kidHome:
                ActivitiesView
                    //.padding(.top, 40)
            case .rewardsStore:
                RewardsStoreView(store: coordinator.rewardsStore)
            default:
                EmptyView()
        }
    }
    
    private var ActivitiesView: some View {
        let notStarted = vmKid.notCompletedRegister()
        let completed = vmKid.completedRegister()
                    //.padding(.top, 40)
        
        return VStack(alignment: .leading, spacing: 24) {
            HStack{
            VStack(alignment: .leading, spacing: 4) {
                
                Text("Atividades para hoje")
                    .kerning(0.4)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                
                Text(Date().formattedDayTitle())
                    .font(.title2)
            HStack{
            }
                
                    HeaderMessage(message: "Parabéns!! Você concluiu a atividade com sucesso!", color: .message)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
        }
            
            if allActivities.isEmpty {
                Text("Hmm... parece que ainda não tem nada pra fazer agora. Que tal pedir pra um adulto adicionar uma atividade bem legal pra você?")
                    .padding(.trailing, 133)
                    .font(.title2)
                if messageCompletedActivy{
                    HeaderMessage(message: "Parabéns!! Você concluiu a atividade com sucesso!", color: .message)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
        }
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
                                    messageCompleted: $messageCompletedActivy
                                    
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
                            }
                            
                            Text("Feito")
                                .font(.title)
                                .kerning(0.38)
                                .fontWeight(.medium)
                            
                                    messageCompleted: $messageCompletedActivy
                                Text("Eita! Ainda não começamos nenhuma atividade hoje... Vamos entrar em ação?")
                                    .padding(.trailing, 133)
                                    .font(.title2)
                                
                            } else {
                                ActivitySection(
                                    registers: completed,
                                    emptyMessage: "",
                                    selectedRegister: $selectedRegister,
                                    vmKid: vmKid,
                                    messageCompleted: $messageCompletedActivy
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
                                    messageCompleted: $messageCompletedActivy
    }
    
    
    private func NavButton(page: Page) -> some View {
        let isSelected = currentPage == page
        return Button {
            currentPage = page
        } label: {
            VStack {
                NavBarView(isSelected: isSelected, page: page)
                    //.frame(width: 137, height: 146)
                    .frame(width: 137, height: 136)
                    .frame(maxHeight: .infinity)
                    .opacity(isSelected ? 1 : 0.5)
    private func NavButton(page: Page, icon: ImageResource) -> some View {
            }
        }
        .disabled(isSelected)
    }
}
                Image(icon)
                    .frame(width: 137, height: 146)
    
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
    @Binding var messageCompleted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if registers.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(registers) { register in
    @Binding var messageCompleted: Bool
                                selectedRegister = register
                            } label: {
                                CardActivity(register: register)
                                    .padding(.leading, 10)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedRegister) { register in
            DetailView(kidViewModel: vmKid, register: register,  onCompletion: {
                messageCompleted = true
                
                                    .padding(.leading, 10)
                        messageCompleted = false
                    }
            })
        }
    }
}

//
                messageCompleted = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        messageCompleted = false
                    }
//#Preview {
//    KidHomeView(vmKid: KidViewModel())
//}
//
//#Preview {
//    KidHomeView(vmKid: KidViewModel())
//}
