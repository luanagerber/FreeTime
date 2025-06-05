//
//  KidView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI
import Combine
import CloudKit

struct KidHomeView: View {
    @State private var currentPage: Page = .kidHome
    @StateObject var vmKid : KidViewModel
    @State var selectedRegister: ActivitiesRegister? = nil
    @EnvironmentObject var coordinator: Coordinator
    @State private var messageCompletedActivy : Bool = false
    
    @State var testNumber = 0
    
    
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
            print("KidHomeView: View appeared - Kid já carregado: \(vmKid.kid?.name ?? "nil")")
            // ✅ REMOVIDO: vmKid.refreshActivities() - agora é feito pelo onReceive
        }
        // ✅ NOVO: onReceive para detectar quando o kid é carregado
        .onReceive(vmKid.kidDidChange) { kid in
            if let kid = kid {
                print("🔄 KidHomeView: Kid carregado via onReceive: \(kid.name)")
                print("🔄 KidHomeView: Iniciando carregamento das atividades...")
                vmKid.loadActivities()
            } else {
                print("🔄 KidHomeView: Kid removido via onReceive")
            }
        }
        .alert("Erro", isPresented: $vmKid.showError) {
            Button("OK") {
                vmKid.clearError()
            }
        } message: {
            Text(vmKid.errorMessage)
        }
        .overlay {
            if vmKid.isLoading && vmKid.kid == nil {
                    // Só mostra overlay quando está carregando o perfil inicial
                    ZStack {
                        Color(.backgroundHeaderYellowKid)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .fontColorKid))
                            
                            Text("Carregando seu perfil...")
                                .foregroundColor(.fontColorKid)
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Aguarde um momento...")
                                .foregroundColor(.fontColorKid.opacity(0.8))
                                .font(.caption)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
        }
    }
    
    private var HeaderView: some View {
        CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight])
            .fill(.backgroundHeaderYellowKid)
            .frame(maxHeight: 156)
            .overlay {
                HStack {
                    HStack(spacing: 24) {
                        // ✅ CORREÇÃO: Usar dados reais do vmKid
                        KidDataView(kidName: vmKid.kidName ?? "Carregando...", kidCoins: vmKid.kidCoins)
                            .padding(.top, 46)
                            .ignoresSafeArea()
                            .frame(maxHeight: 156, alignment: .top)
                            .onTapGesture {
                                withAnimation {
                                    testNumber += 5
                                }
                            }
                    }
                    Spacer()
                    HStack(spacing: 39) {
                        NavButton(page: .kidHome)
                        NavButton(page: .rewardsStore)
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
                .padding(.top, 40)
        case .rewardsStore:
            RewardsStoreView(store: coordinator.rewardsStore)
        default:
            EmptyView()
        }
    }
    
    private var ActivitiesView: some View {
            // ✅ NOVO: Estados baseados no carregamento
            return Group {
                if vmKid.kid == nil {
                // Kid ainda não carregou
                VStack(spacing: 16) {
                    ProgressView("Carregando perfil...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .fontColorKid))
                        .foregroundColor(.fontColorKid)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .padding()
                
            } else if vmKid.isLoadingActivities {
                // Kid carregado, mas atividades ainda carregando
                VStack(spacing: 16) {
                    ProgressView("Carregando suas atividades...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .fontColorKid))
                        .foregroundColor(.fontColorKid)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .padding()
                
            } else {
                // ✅ Tudo carregado - mostrar atividades
                let notStarted = vmKid.notCompletedRegister()
                let completed = vmKid.completedRegister()
                let allActivities = notStarted + completed
                
                // Debug info
                let _ = print("🔍 KidHomeView DEBUG:")
                let _ = print("  - Kid carregado: \(vmKid.kid?.name ?? "nil")")
                let _ = print("  - Total atividades carregadas: \(vmKid.activities.count)")
                let _ = print("  - Atividades de hoje (não concluídas): \(notStarted.count)")
                let _ = print("  - Atividades de hoje (concluídas): \(completed.count)")
                let _ = print("  - Total de hoje: \(allActivities.count)")
                
                let allKidActivities = vmKid.allActivitiesForKid()
                let _ = print("  - Todas as atividades do kid: \(allKidActivities.count)")
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    HStack(alignment: .center){
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Text("Atividades para hoje")
                                .kerning(0.4)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                            
                            Text(Date().formattedDayTitle())
                                .font(.title2)
                                .kerning(0.3)
                        }
                        
                        if messageCompletedActivy{
                            HeaderMessage(message: "Parabéns!! Você concluiu a atividade com sucesso!", color: .message)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            messageCompletedActivy = false
                                        }
                                    }
                                }
                        }
                    }
                    
                    if allActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hmm... parece que ainda não tem nada pra fazer agora. Que tal pedir pra um adulto adicionar uma atividade bem legal pra você?")
                                .padding(.trailing, 133)
                                .font(.title2)
                            
                        }
                        
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
                                        ActivitySectionView(
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
                                    
                                    if completed.isEmpty {
                                        Text("Eita! Ainda não começamos nenhuma atividade hoje... Vamos entrar em ação?")
                                            .padding(.trailing, 133)
                                            .font(.title2)
                                        
                                    } else {
                                        ActivitySectionView(
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
                .padding(.leading, 133)
            }
        }
            .fontDesign(.rounded)
        }
    
    private func NavButton(page: Page) -> some View {
        let isSelected = currentPage == page
        return Button {
            currentPage = page
        } label: {
            VStack {
                NavBarView(isSelected: isSelected, page: page)
                    .frame(width: 137, height: 136)
                    .frame(maxHeight: .infinity)
                    .opacity(isSelected ? 1 : 0.5)
                    .padding(.top, 9)
            }
        }
        .disabled(isSelected)
    }
}

#Preview("KidHome") {
    
    struct PreviewWrapper: View {
        @StateObject var coordinator = Coordinator()
        
        
        var body: some View {
            NavigationStack(path: $coordinator.path) {
                KidHomeView(vmKid: coordinator.vmKid)
                    .navigationDestination(for: Page.self) { page in
                        coordinator.build(page: page)
                    }
                    .sheet(item: $coordinator.sheet) { sheet in
                        coordinator.build(sheet: sheet)
                            .presentationSizing(.fitted)
                            .presentationCornerRadius(20)
                    }
                    .onAppear {
                        coordinator.vmKid.loadTestActivities()
                    }
            }
            .environmentObject(coordinator)
        }
    }
    return PreviewWrapper()
}
