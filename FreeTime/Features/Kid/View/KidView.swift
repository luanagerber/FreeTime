//  KidView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI
import CloudKit

struct KidView: View {
    
    @State private var currentPage: Page = .kidHome
    @StateObject private var vmKid = ViewModelKid()
    
    @State private var selectedRegister: ActivitiesRegister? = ActivitiesRegister.sample1
    @State private var showActivityModal: Bool = false
    
    var body: some View {
        ZStack{
            VStack(alignment: .leading, spacing: 0) {
                Section {
                    Rectangle()
                        .fill(.gray)
                        .cornerRadius(18)
                        .frame(maxWidth: .infinity, maxHeight: 126)
                        .overlay{
                            HStack(spacing: 20){
                                
                                kidData
                                
                                Spacer()
                                
                                buttonsDestinations(title: "Atividades", destination: .kidHome)
                                Divider()
                                    .frame(width: 2, height: 70)
                                    .background(Color.white)
                                
                                buttonsDestinations(title: "Lojinha", destination: .rewardsStore)
                            }
                            .padding(.horizontal, 30)
                            .foregroundColor(.white)
                        }
                }
                
                if currentPage == .kidHome {
                    ActivitiesView
                        .border(.red)
                } else if currentPage == .rewardsStore {
                    RewardsStoreView(store: .init())
                        .border(.blue)
                }
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        
    }
    
    @ViewBuilder
    private var kidData: some View {
        
        Circle()//Kid Image
            .frame(width: 50, height: 50)
        
        VStack(alignment: .leading, spacing: 10){
            
            Text(vmKid.kid.name)
                .font(.system(size: 20, weight: .bold, design: .default))
            Text("$ \(vmKid.kid.coins)")
                .font(.system(size: 17, weight: .regular, design: .default))
        }
    }
    private func buttonsDestinations(title: String, destination: Page) -> some View {
            let isCurrent = destination == currentPage

            return Button {
                if !isCurrent {
                    currentPage = destination
                }
            } label: {
                VStack {
                    Rectangle()
                        .fill(isCurrent ? Color.green : Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .cornerRadius(20)
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(isCurrent)
        }

    @ViewBuilder
    private var ActivitiesView: some View {
        
        VStack(alignment: .leading, spacing: 32) {
            headerSection
            activitySection(
                title: "Para fazer",
                registers: ActivitiesRegister.samples,
                emptyMessage: "Não há atividades a serem realizadas hoje."
            )
            
//            let completed = kidViewModel.completedRegister(kidId: kidId)
//            if !completed.isEmpty {
//                activitySection(
//                    title: "Feito",
//                    registers: completed,
//                    emptyMessage: ""
//                )
//            }
        }
        .padding(.horizontal, 132.5)
        .padding(.vertical, 32)
    }
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Atividades para hoje")
                .font(.system(size: 34, weight: .semibold))
            Text(Date().formattedDayTitle())
                .font(.system(size: 22))
        }
    }
    private func activitySection(title: String, registers: [ActivitiesRegister], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .medium))
            
            if registers.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .sheet(isPresented: $showActivityModal) {
                            if let bindingRegister = Binding($selectedRegister) {
                                DetailsActivityModal(kidViewModel: vmKid, register: bindingRegister)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250,maxHeight: .infinity, alignment: .top)
    }
}


#Preview {
    CoordinatorView()
}
