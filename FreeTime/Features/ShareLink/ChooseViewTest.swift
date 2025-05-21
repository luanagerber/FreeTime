//
//  ChooseViewTest.swift
//  FreeTime
//
//  Created by Maria Tereza Martins Pérez on 21/05/25.
//

import SwiftUI
import CloudKit

enum UserRole: String {
    case parent = "Pai/Mãe"
    case kid = "Filho(a)"
}

struct ChooseViewTest: View {
    @AppStorage("userRole") private var userRole: String?
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Escolha seu papel")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                roleButton(role: .parent)
                roleButton(role: .kid)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func roleButton(role: UserRole) -> some View {
        Button {
            userRole = role.rawValue
        } label: {
            HStack {
                Image(systemName: role == .parent ? "person.3" : "person.circle")
                    .font(.title2)
                
                Text(role.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct RoleBasedView: View {
    @AppStorage("userRole") private var userRole: String?
    
    var body: some View {
        if let role = userRole {
            switch role {
            case UserRole.parent.rawValue:
                ParentSharerView()
            case UserRole.kid.rawValue:
                KidReceiverView()
            default:
                ChooseViewTest()
            }
        } else {
            ChooseViewTest()
        }
    }
}

#Preview {
    ChooseViewTest()
}
