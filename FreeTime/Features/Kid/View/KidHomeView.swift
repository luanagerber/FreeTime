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
    @State private var showActivityModal: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView
                contentView
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear {
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
            .fill(.gray)
            .cornerRadius(18)
            .frame(height: 126)
            .overlay {
                HStack(spacing: 20) {
                    KidDataView(kid: vmKid.kid ?? Kid(name: "", coins: 0))
                    Spacer()
                    NavButton(title: "Atividades", page: .kidHome)
                    Divider().frame(width: 2, height: 70).background(Color.white)
                    NavButton(title: "Lojinha", page: .rewardsStore)
                }
                .padding(.horizontal, 30)
                .foregroundColor(.white)
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch currentPage {
        case .kidHome:
            ActivitiesView
        case .rewardsStore:
            RewardsStoreView(store: .init())
        default:
            EmptyView()
        }
    }

    private var ActivitiesView: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Atividades para hoje")
                    .font(.system(size: 34, weight: .semibold))
                Text(Date().formattedDayTitle())
                    .font(.system(size: 22))
            }

            // Atividades Para Fazer (não iniciadas + em progresso)
            ActivitySection(
                title: "Para fazer",
                registers: vmKid.notStartedRegister() + vmKid.inProgressRegister(),
                emptyMessage: "Não há atividades a serem realizadas hoje.",
                selectedRegister: $selectedRegister,
                showActivityModal: $showActivityModal,
                vmKid: vmKid
            )
            
            // Atividades Concluídas
            ActivitySection(
                title: "Concluídas",
                registers: vmKid.completedRegister(),
                emptyMessage: "Nenhuma atividade concluída hoje.",
                selectedRegister: $selectedRegister,
                showActivityModal: $showActivityModal,
                vmKid: vmKid
            )
        }
        .padding(.leading, 132)
        .padding(.vertical, 32)
    }

    private func NavButton(title: String, page: Page) -> some View {
        let isSelected = currentPage == page
        return Button {
            currentPage = page
        } label: {
            VStack {
                Rectangle()
                    .fill(isSelected ? Color.green : Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .cornerRadius(20)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .disabled(isSelected)
    }
}

struct KidDataView: View {
    let kid: Kid

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(kid.name)
                    .font(.system(size: 20, weight: .bold))
                Text("$ \(kid.coins)")
                    .font(.system(size: 17))
            }
        }
    }
}

struct ActivitySection: View {
    let title: String
    let registers: [ActivitiesRegister]
    let emptyMessage: String
    @Binding var selectedRegister: ActivitiesRegister?
    @Binding var showActivityModal: Bool
    var vmKid: KidViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .medium))

            if registers.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(registers) { register in
                            Button {
                                selectedRegister = register
                                showActivityModal = true
                            } label: {
                                CardActivity(register: register)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showActivityModal) {
            if let register = selectedRegister {
                DetailView(kidViewModel: vmKid, register: register)
            }
        }
    }
}

#Preview {
    KidHomeView()
}
