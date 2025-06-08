//
//  UserRole.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import Foundation
import SwiftUI

enum InvitationStatus: String, CaseIterable {
    case sent
    case pending
    case accepted
}

class InvitationStatusManager: ObservableObject {
    static let shared = InvitationStatusManager()
    
    @AppStorage("invitationStatus") var invitationStatus: String = InvitationStatus.pending.rawValue
    
    private init() {}
    
    var currentStatus: InvitationStatus {
        get {
            InvitationStatus(rawValue: invitationStatus) ?? .pending
        }
        set {
            invitationStatus = newValue.rawValue
        }
    }
    
    func updateStatus(to status: InvitationStatus) {
        currentStatus = status
    }
    
    // For compatibility with UserDefaults usage
    #warning("Declarar uma constante para armazenar a chave do UserDefaults, menos chance de erro de grafia.")

    static func setStatus(_ status: InvitationStatus) {
        UserDefaults.standard.setValue(status.rawValue, forKey: "invitationStatus")
        shared.currentStatus = status
    }
    
    static func getStatus() -> InvitationStatus {
        let rawValue = UserDefaults.standard.string(forKey: "invitationStatus") ?? InvitationStatus.pending.rawValue
        return InvitationStatus(rawValue: rawValue) ?? .pending
    }
}

