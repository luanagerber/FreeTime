// UserManager.swift
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
        // Primeiro inicializa as propriedades @Published com valores temporários
        self.userRole = .undefined
        self.currentKidID = nil
        self.currentKidName = ""
        
        // Depois atualiza com os valores salvos
        // Usa uma closure para acessar self de forma segura
        let savedRole = UserDefaults.standard.string(forKey: "userRole") ?? UserRole.undefined.rawValue
        let savedKidName = UserDefaults.standard.string(forKey: "currentKidName") ?? ""
        let savedKidRecordName = UserDefaults.standard.string(forKey: "currentKidRecordName") ?? ""
        
        self.userRole = UserRole(rawValue: savedRole) ?? .undefined
        self.currentKidName = savedKidName
        
        // Reconstrói o CKRecord.ID se existir
        if !savedKidRecordName.isEmpty {
            self.currentKidID = CKRecord.ID(
                recordName: savedKidRecordName,
                zoneID: CloudConfig.recordZone.zoneID
            )
        }
    }
    
    // MARK: - Parent Methods
    
    func setAsParent(withKid kid: Kid) {
        guard let kidID = kid.id else {
            print("UserManager Error: Kid doesn't have a valid ID")
            return
        }
        
        self.userRole = .parent
        self.currentKidID = kidID
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
        guard let kidID = kid.id else {
            print("UserManager Error: Kid doesn't have a valid ID")
            return
        }
        
        self.userRole = .child
        self.currentKidID = kidID
        self.currentKidName = kid.name
        
        CloudService.shared.saveRootRecordID(kidID)
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
