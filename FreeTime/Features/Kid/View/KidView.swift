//  KidView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI
import CloudKit

struct KidView: View {
    
    @StateObject private var kidViewModel = KidViewModel()
    
    //Testing with mocked-up data
    let kidExample : Kid = Kid.sample
    let kidId: CKRecord.ID? = Kid.sample.id
    //
    
    @State private var selectedRegister: ActivitiesRegister? = ActivitiesRegister.sample1
    @State private var showActivityModal: Bool = false
    
    var body: some View {
//        ZStack{
//            VStack(spacing: 0) {
//                Section {
//                    SectionProfile(kid: kidExample)
//                }
//                
//                VStack(alignment: .leading, spacing: 32) {
//                    headerSection
//                    activitySection(
//                        title: "Para fazer",
//                        registers: kidViewModel.notStartedRegister(kidId: kidId),
//                        emptyMessage: "Não há atividades a serem realizadas hoje."
//                    )
//                    
//                    let completed = kidViewModel.completedRegister(kidId: kidId)
//                    if !completed.isEmpty {
//                        activitySection(
//                            title: "Feito",
//                            registers: completed,
//                            emptyMessage: ""
//                        )
//                    }
//                }
//                .padding(.horizontal, 132.5)
//                .padding(.vertical, 32)
//            }
//            .frame(maxHeight: .infinity, alignment: .top)
//        }
//        .ignoresSafeArea()
//        
//        
//    }
//    
//    private var headerSection: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text("Atividades para hoje")
//                .font(.system(size: 34, weight: .semibold))
//            Text(Date().formattedDayTitle())
//                .font(.system(size: 22))
//        }
//    }
//    
//    private func activitySection(title: String, registers: [Register], emptyMessage: String) -> some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text(title)
//                .font(.system(size: 28, weight: .medium))
//            
//            if registers.isEmpty {
//                Text(emptyMessage)
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            } else {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 32) {
//                        ForEach(registers) { register in
//                            Button {
//                                selectedRegister = register
//                                showActivityModal = true
//                            } label: {
//                                CardActivity(register: register)
//                            }
//                        }
//                        .sheet(isPresented: $showActivityModal) {
//                            if let bindingRegister = Binding($selectedRegister) {
//                                DetailsActivityModal(kidViewModel: kidViewModel, register: bindingRegister)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, minHeight: 250,maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    KidView()
}
