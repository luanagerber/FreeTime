//
//  Record.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation
import CloudKit
import SwiftUI

struct ActivitiesRegister: Identifiable {
    var id: CKRecord.ID?
    let kidID: String // Stores the recordName of the Kid
    let activityID: Int // Novo formato: Int para referenciar Activity catalog
    let date: Date
    let duration: TimeInterval
    var registerStatus: RegisterStatus
    
    // CloudKit related properties
    var shareReference: CKRecord.Reference?
    var kidReference: CKRecord.Reference?
        
    // For Identifiable conformance (UUID required if id is nil)
    private let localID = UUID()
    
    init(kidID: String, activityID: Int, date: Date, duration: TimeInterval, registerStatus: RegisterStatus = .notCompleted) {
        self.kidID = kidID
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
    }
    
    init(kid: Kid, activityID: Int, date: Date, duration: TimeInterval, registerStatus: RegisterStatus = .notCompleted) {
        self.kidID = kid.id?.recordName ?? ""
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
        
        if let kidRecordID = kid.id {
            self.kidReference = CKRecord.Reference(recordID: kidRecordID, action: .deleteSelf)
        }
    }
    
    // Computed property to fetch the activity from the catalog
    var activity: Activity? {
        Activity.find(by: activityID)
    }
}

// RecordProtocol extension
extension ActivitiesRegister: RecordProtocol {
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.activity.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidID"] = kidID
        newRecord["activityID"] = String(activityID) // Convert Int to String for CloudKit
        newRecord["date"] = date
        newRecord["duration"] = duration
        newRecord["status"] = registerStatus.rawValue
        
        // Add reference to parent Kid if available
        if let kidRef = kidReference {
            newRecord["kidReference"] = kidRef
        }
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.activity.rawValue, recordID: recordID)
        record["kidID"] = kidID
        record["activityID"] = String(activityID) // Convert Int to String for CloudKit
        record["date"] = date
        record["duration"] = duration
        record["status"] = registerStatus.rawValue
        
        // Adicionar referência ao Kid se disponível
        if let kidRef = kidReference {
            record["kidReference"] = kidRef
        }
        
        return record
    }
    
    init?(record: CKRecord) {
        print("🔧 INIT: Tentando criar ActivitiesRegister do record: \(record.recordID.recordName)")
        print("🔧 INIT: Campos disponíveis: \(record.allKeys())")
        print("🔧 INIT: Valores dos campos:")
        for key in record.allKeys() {
            print("  - \(key): \(record[key] ?? "nil") (tipo: \(type(of: record[key])))")
        }
        
        guard
            let kidID = record["kidID"] as? String,
            let date = record["date"] as? Date,
            let duration = record["duration"] as? TimeInterval,
            let statusRawValue = record["status"] as? Int,
            let status = RegisterStatus(rawValue: statusRawValue) else {
                
                print("🔧 INIT: ❌ Falha na conversão dos campos básicos:")
                print("  - kidID: \(record["kidID"] ?? "nil") -> String? \(record["kidID"] as? String != nil ? "✅" : "❌")")
                print("  - date: \(record["date"] ?? "nil") -> Date? \(record["date"] as? Date != nil ? "✅" : "❌")")
                print("  - duration: \(record["duration"] ?? "nil") -> TimeInterval? \(record["duration"] as? TimeInterval != nil ? "✅" : "❌")")
                print("  - status: \(record["status"] ?? "nil") -> Int? \(record["status"] as? Int != nil ? "✅" : "❌")")
                
                return nil
        }
        
        // MIGRAÇÃO: Tentar String primeiro (novo formato), depois Int (antigo formato)
        var finalActivityID: Int
        
        if let activityIDString = record["activityID"] as? String {
            // Novo formato: String (convertido do Int)
            if let activityIDInt = Int(activityIDString) {
                print("🔧 INIT: ✅ ActivityID encontrado como String convertível para Int: \(activityIDString) -> \(activityIDInt)")
                finalActivityID = activityIDInt
            } else {
                // Formato legacy: String (UUID) - converter para Int baseado em mapeamento
                print("🔧 INIT: ⚠️ ActivityID encontrado como String (UUID): \(activityIDString)")
                
                // Mapeamento de UUIDs antigos para novos IDs Int
                let uuidToIntMapping: [String: Int] = [
                    "D118C97D-03B9-48CB-84FA-A8257980BD9A": 0, // Exemplo: mapear para Pintura Criativa
                    "5BB0D5CC-FC78-44B1-B56A-7CF00C0EBF51": 1, // Exemplo: mapear para Experimento de Vulcão
                    "DBDEEE3F-38CA-4270-A734-802D00FACD01": 2, // Exemplo: mapear para Brincar de esconde esconde
                    // Adicione mais mapeamentos conforme necessário
                ]
                
                if let mappedID = uuidToIntMapping[activityIDString] {
                    print("🔧 INIT: ✅ UUID mapeado para Int: \(activityIDString) -> \(mappedID)")
                    finalActivityID = mappedID
                } else {
                    print("🔧 INIT: ❌ UUID não encontrado no mapeamento: \(activityIDString)")
                    // Usar ID padrão (0) para UUIDs desconhecidos
                    finalActivityID = 0
                    print("🔧 INIT: ⚠️ Usando ID padrão 0 para UUID desconhecido")
                }
            }
        } else if let activityIDInt = record["activityID"] as? Int {
            // Formato muito antigo: Int direto (não deveria mais acontecer após a correção)
            print("🔧 INIT: ⚠️ ActivityID encontrado como Int direto: \(activityIDInt)")
            finalActivityID = activityIDInt
        } else {
            print("🔧 INIT: ❌ ActivityID não é nem String nem Int")
            return nil
        }
        
        print("🔧 INIT: ✅ Conversão bem-sucedida!")
        print("🔧 INIT: Dados convertidos:")
        print("  - kidID: \(kidID)")
        print("  - activityID: \(finalActivityID)")
        print("  - date: \(date)")
        print("  - duration: \(duration)")
        print("  - status: \(status)")
        
        self.id = record.recordID
        self.kidID = kidID
        self.activityID = finalActivityID
        self.date = date
        self.duration = duration
        self.registerStatus = status
        self.shareReference = record.share
        self.kidReference = record["kidReference"] as? CKRecord.Reference
        
        print("🔧 INIT: ✅ ActivitiesRegister criado com sucesso!")
    }
}

// Equatable and Hashable extensions
extension ActivitiesRegister: Equatable, Hashable {
    static func == (lhs: ActivitiesRegister, rhs: ActivitiesRegister) -> Bool {
        // If we have CloudKit IDs, compare those
        if let lhsID = lhs.id, let rhsID = rhs.id {
            return lhsID == rhsID
        }
        
        // Otherwise compare the content
        return lhs.localID == rhs.localID &&
            lhs.kidID == rhs.kidID &&
            lhs.activityID == rhs.activityID &&
            lhs.date == rhs.date &&
            lhs.duration == rhs.duration &&
            lhs.registerStatus == rhs.registerStatus
    }
    
    func hash(into hasher: inout Hasher) {
        // If we have a CloudKit ID, hash that
        if let cloudID = id {
            hasher.combine(cloudID)
            return
        }
        
        // Otherwise hash the content
        hasher.combine(localID)
        hasher.combine(kidID)
        hasher.combine(activityID)
        hasher.combine(date)
        hasher.combine(duration)
        hasher.combine(registerStatus)
    }
}
