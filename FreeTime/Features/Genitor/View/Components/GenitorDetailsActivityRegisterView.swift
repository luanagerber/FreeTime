//
//  GenitorDetailsActivityRegisterView.swift
//  FreeTime
//
//  Created by Thales Araújo on 04/06/25.
//

import SwiftUI

struct GenitorDetailsActivityRegisterView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm = GenitorViewModel.shared
    
    @State private var isDeleting = false
    @State private var exclusionConfirmation = false
    
    var body: some View {
        VStack {
            
            // Sair
            Button(action: {
                dismiss()
                vm.isSelectedActivity = false
                vm.selectedActivityRegister = nil
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .tint(Color.gray)
            })
            .hSpacing(.bottomTrailing)
            .padding(.bottom, 5)
            
            // Título
            Text("Detalhes da atividade")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color("primaryColor"))
                .hSpacing(.leading)
                .padding(.bottom, 40)
            
            // Campos da atividade
            VStack(spacing: 20) {
                
                // Nome
                HStack {
                    Text("Atividade")
                        .font(.system(size: 17, weight: .medium))
                    
                    Spacer()
                    
                    Text(vm.selectedActivityRegister?.activity?.name ?? "Atividade Nome")
                        .font(.system(size: 17))
                }
                .padding()
                .background(Color.white)
                .foregroundColor(Color("primaryColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // Descrição
                HStack {
                    Text(vm.selectedActivityRegister?.activity?.description ?? "Descrição")
                        .font(.system(size: 17))
                        
                }
                .padding()
                .foregroundColor(Color("primaryColor"))
                .hSpacing(.leading)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // valor da atividade
                HStack {
                    Text("Valor da atividade")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(vm.selectedActivityRegister?.activity?.rewardPoints.description ?? "0")
                        
                    Image(systemName: "dollarsign.circle.fill")
                    
                    
                }
                .font(.system(size: 17))
                .foregroundColor(Color("primaryColor"))
                .hSpacing(.leading)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // data da atividade
                HStack {
                    Text("Data")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text( vm.selectedActivityRegister?.date.formattedAsDayMonthAndHour() ?? "nil")
                }
                .font(.system(size: 17))
                .foregroundStyle(Color("primaryColor"))
                .hSpacing(.leading)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 2)
                )
                
                // Deletar
                Button(action: {
                    exclusionConfirmation = true
                }, label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Deletar Atividade")
                        }
                    }
                    //.font(.custom("SF Pro", size: 17, relativeTo: .body))
                    .font(.system(size: 17, weight: .bold))
                    //.fontWeight(.bold)
                    .foregroundColor(isDeleting
                                     ? Color("primaryColor").opacity(0.4)
                                     : Color("primaryColor")
                    )
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(isDeleting
                                ? Color("ErrorMessage").opacity(0.4)
                                : Color("ErrorMessage")
                    )
                    .cornerRadius(40)
                })
                .disabled(isDeleting)
            }
            
        }
        .hSpacing(.leading)
        .vSpacing(.top)
        .padding()
        .background(Color("backgroundGenitor"))
        .alert("Deletar atividade?", isPresented: $exclusionConfirmation) {
            Button("Cancelar", role: .cancel) {
                exclusionConfirmation = false
            }
//            Button("Deletar", role: .destructive) {
//                isDeleting = true
//                //deleteActivity()
//            }
            
            Button("Deletar", role: .destructive) {
                isDeleting = true
                vm.deleteActivity()
            }
        } message: {
            Text("Essa ação é permanente e não poderá ser desfeita")
        }

    }
}

#Preview {
    GenitorDetailsActivityRegisterView()
}
