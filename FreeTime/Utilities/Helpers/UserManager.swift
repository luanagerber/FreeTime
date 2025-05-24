//
//  UserManager.swift
//  FreeTime
//
//  Created by Luana Gerber on 24/05/25.
//

import SwiftUI
import CloudKit

enum UserRole: String {
    case parent = "parent"
    case child = "child"
    case undefined = "undefined"
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @AppStorage("userRole") private var storedRole: String = UserRole.undefined.rawValue
    @AppStorage("currentKidRecordName") private var storedKidRecordName: String = ""
    @AppStorage("currentKidName") private var storedKidName: String = ""
    
    @Published var userRole: UserRole {
        didSet {
            storedRole = userRole.rawValue
        }
    }
    
    @Published var currentKidID: CKRecord.ID? {
        didSet {
            if let kidID = currentKidID {
                storedKidRecordName = kidID.recordName
            } else {
                storedKidRecordName = ""
            }
        }
    }
    
    @Published var currentKidName: String {
        didSet {
            storedKidName = currentKidName
        }
    }
    
    private init() {
        // Inicializa com valores salvos
        self.userRole = UserRole(rawValue: storedRole) ?? .undefined
        self.currentKidName = storedKidName
        
        // Reconstrói o CKRecord.ID se existir
        if !storedKidRecordName.isEmpty {
            self.currentKidID = CKRecord.ID(
                recordName: storedKidRecordName,
                zoneID: CloudConfig.recordZone.zoneID
            )
        }
    }
    
    // MARK: - Parent Methods
    
    func setAsParent(withKid kid: Kid) {
        self.userRole = .parent
        self.currentKidID = kid.id
        self.currentKidName = kid.name
    }
    
    func setAsParent(withKidID kidID: CKRecord.ID, name: String) {
        self.userRole = .parent
        self.currentKidID = kidID
        self.currentKidName = name
    }
    
    // MARK: - Child Methods
    
    func setAsChild(withKidID kidID: CKRecord.ID, name: String) {
        self.userRole = .child
        self.currentKidID = kidID
        self.currentKidName = name
        
        // Também salva no CloudService para compatibilidade
        CloudService.shared.saveRootRecordID(kidID)
    }
    
    func setAsChild(withKid kid: Kid) {
        self.userRole = .child
        self.currentKidID = kid.id
        self.currentKidName = kid.name
        
        CloudService.shared.saveRootRecordID(kid.id)
    }
    
    // MARK: - Helper Methods
    
    var isParent: Bool {
        return userRole == .parent
    }
    
    var isChild: Bool {
        return userRole == .child
    }
    
    var hasValidKid: Bool {
        return currentKidID != nil && !currentKidName.isEmpty
    }
    
    func reset() {
        userRole = .undefined
        currentKidID = nil
        currentKidName = ""
        storedKidRecordName = ""
        storedKidName = ""
        storedRole = UserRole.undefined.rawValue
    }
    
    // MARK: - Debug Helper
    
    var debugDescription: String {
        """
        UserManager Debug:
        - Role: \(userRole.rawValue)
        - Kid Name: \(currentKidName.isEmpty ? "None" : currentKidName)
        - Kid ID: \(currentKidID?.recordName ?? "None")
        """
    }
}
