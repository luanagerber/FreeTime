//
//  UserManager.swift
//  FreeTime
//
//  Created by Luana Gerber on 22/05/25.
//

import SwiftUI
import CloudKit

enum UserRole: String {
    case genitor = "parent"
    case kid = "child"
    case undefined = "undefined"
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @AppStorage("userRole") private var storedRole: String = UserRole.undefined.rawValue
    @AppStorage("currentKidRecordName") private var storedKidRecordName: String = ""
    @AppStorage("currentKidName") private var storedKidName: String = ""
    @AppStorage("currentKidZoneName") private var storedKidZoneName: String = ""
    @AppStorage("currentKidZoneOwner") private var storedKidZoneOwner: String = ""
    
    @Published var userRole: UserRole {
        didSet {
            storedRole = userRole.rawValue
        }
    }
    
    @Published var currentKidID: CKRecord.ID? {
        didSet {
            if let kidID = currentKidID {
                storedKidRecordName = kidID.recordName
                storedKidZoneName = kidID.zoneID.zoneName
                storedKidZoneOwner = kidID.zoneID.ownerName
            } else {
                storedKidRecordName = ""
                storedKidZoneName = ""
                storedKidZoneOwner = ""
            }
        }
    }
    
    @Published var currentKidName: String {
        didSet {
            storedKidName = currentKidName
        }
    }
    
    private init() {
        // Primeiro inicializa as propriedades @Published com valores temporários
        self.userRole = .undefined
        self.currentKidID = nil
        self.currentKidName = ""
        
        // Depois atualiza com os valores salvos
        let savedRole = UserDefaults.standard.string(forKey: "userRole") ?? UserRole.undefined.rawValue
        let savedKidName = UserDefaults.standard.string(forKey: "currentKidName") ?? ""
        let savedKidRecordName = UserDefaults.standard.string(forKey: "currentKidRecordName") ?? ""
        let savedKidZoneName = UserDefaults.standard.string(forKey: "currentKidZoneName") ?? ""
        let savedKidZoneOwner = UserDefaults.standard.string(forKey: "currentKidZoneOwner") ?? ""
        
        self.userRole = UserRole(rawValue: savedRole) ?? .undefined
        self.currentKidName = savedKidName
        
        // CORREÇÃO: Reconstrói o CKRecord.ID com a zona original
        if !savedKidRecordName.isEmpty {
            let zoneID: CKRecordZone.ID
            
            if !savedKidZoneName.isEmpty && !savedKidZoneOwner.isEmpty {
                // IMPORTANTE: Verificar se é zona compartilhada
                if savedKidZoneOwner != CKCurrentUserDefaultName {
                    // É uma zona compartilhada
                    zoneID = CKRecordZone.ID(zoneName: savedKidZoneName, ownerName: savedKidZoneOwner)
                    print("UserManager: Reconstituindo kidID com zona COMPARTILHADA: \(savedKidZoneName):\(savedKidZoneOwner)")
                } else {
                    // É zona privada
                    zoneID = CKRecordZone.ID(zoneName: savedKidZoneName, ownerName: savedKidZoneOwner)
                    print("UserManager: Reconstituindo kidID com zona PRIVADA: \(savedKidZoneName):\(savedKidZoneOwner)")
                }
            } else {
                // Fallback para zona padrão
                zoneID = CloudConfig.recordZone.zoneID
                print("UserManager: Usando zona padrão como fallback")
            }
            
            self.currentKidID = CKRecord.ID(recordName: savedKidRecordName, zoneID: zoneID)
            
            print("UserManager: KidID reconstituído:")
            print("  - Record Name: \(savedKidRecordName)")
            print("  - Zone: \(zoneID.zoneName):\(zoneID.ownerName)")
            print("  - É zona compartilhada? \(zoneID.ownerName != CKCurrentUserDefaultName)")
        }
    }
    
    // MARK: - Parent Methods
    
    func setAsParent(withKid kid: Kid) {
        guard let kidID = kid.id else {
            print("UserManager Error: Kid doesn't have a valid ID")
            return
        }
        
        print("UserManager: Definindo como pai com Kid: \(kid.name)")
        print("  - Kid ID: \(kidID.recordName)")
        print("  - Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        
        self.userRole = .genitor
        self.currentKidID = kidID
        self.currentKidName = kid.name
    }
    
    func setAsParent(withKidID kidID: CKRecord.ID, name: String) {
        print("UserManager: Definindo como pai com KidID: \(name)")
        print("  - Kid ID: \(kidID.recordName)")
        print("  - Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        
        self.userRole = .genitor
        self.currentKidID = kidID
        self.currentKidName = name
    }
    
    // MARK: - Child Methods
    
    func setAsChild(withKidID kidID: CKRecord.ID, name: String) {
        print("UserManager: Definindo como criança: \(name)")
        print("  - Kid ID: \(kidID.recordName)")
        print("  - Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        print("  - É zona compartilhada? \(kidID.zoneID.ownerName != CKCurrentUserDefaultName)")
        
        self.userRole = .kid
        self.currentKidID = kidID
        self.currentKidName = name
        
        // Também salva no CloudService para compatibilidade
        CloudService.shared.saveRootRecordID(kidID)
    }
    
    func setAsChild(withKid kid: Kid) {
        guard let kidID = kid.id else {
            print("UserManager Error: Kid doesn't have a valid ID")
            return
        }
        
        print("UserManager: Definindo como criança com Kid: \(kid.name)")
        print("  - Kid ID: \(kidID.recordName)")
        print("  - Zone: \(kidID.zoneID.zoneName):\(kidID.zoneID.ownerName)")
        print("  - É zona compartilhada? \(kidID.zoneID.ownerName != CKCurrentUserDefaultName)")
        
        self.userRole = .kid
        self.currentKidID = kidID
        self.currentKidName = kid.name
        
        CloudService.shared.saveRootRecordID(kidID)
    }
    
    // MARK: - Helper Methods
    
    var isParent: Bool {
        return userRole == .genitor
    }
    
    var isChild: Bool {
        return userRole == .kid
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
        storedKidZoneName = ""
        storedKidZoneOwner = ""
        storedRole = UserRole.undefined.rawValue
    }
    
    // MARK: - Debug Helper
    
    var debugDescription: String {
        let zoneInfo = currentKidID?.zoneID
        let isSharedZone = zoneInfo?.ownerName != CKCurrentUserDefaultName
        return """
        UserManager Debug:
        - Role: \(userRole.rawValue)
        - Kid Name: \(currentKidName.isEmpty ? "None" : currentKidName)
        - Kid ID: \(currentKidID?.recordName ?? "None")
        - Zone: \(zoneInfo?.zoneName ?? "None"):\(zoneInfo?.ownerName ?? "None")
        - É zona compartilhada? \(isSharedZone)
        """
    }
}
