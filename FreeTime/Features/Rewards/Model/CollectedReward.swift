//
//  CollectedReward.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 13/05/25.
//

import Foundation
import CloudKit

#warning("remover prints")

struct CollectedReward: Identifiable {
    var id: CKRecord.ID?
    let kidID: String // Stores the recordName of the Kid
    let rewardID: Int // Reference to Reward from catalog
    let dateCollected: Date
    var isDelivered: Bool // Father marks if already gave it to child
    
    // CloudKit related properties
    var shareReference: CKRecord.Reference?
    var kidReference: CKRecord.Reference?
    
    // For Identifiable conformance (UUID required if id is nil)
    private let localID = UUID()
    
    init(kidID: String, rewardID: Int, dateCollected: Date, isDelivered: Bool = false) {
        self.kidID = kidID
        self.rewardID = rewardID
        self.dateCollected = dateCollected
        self.isDelivered = isDelivered
    }
    
    init(kid: Kid, rewardID: Int, dateCollected: Date, isDelivered: Bool = false) {
        self.kidID = kid.id?.recordName ?? ""
        self.rewardID = rewardID
        self.dateCollected = dateCollected
        self.isDelivered = isDelivered
        
        if let kidRecordID = kid.id {
            self.kidReference = CKRecord.Reference(recordID: kidRecordID, action: .deleteSelf)
        }
    }
    
    // Computed property to fetch the reward from the catalog
    var reward: Reward? {
        Reward.find(by: rewardID)
    }
}

// RecordProtocol extension
extension CollectedReward: RecordProtocol {
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.collectedReward.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidID"] = kidID
        newRecord["rewardID"] = rewardID
        newRecord["dateCollected"] = dateCollected
        newRecord["isDelivered"] = isDelivered
        
        // Add reference to parent Kid if available
        if let kidRef = kidReference {
            newRecord["kidReference"] = kidRef
        }
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.collectedReward.rawValue, recordID: recordID)
        record["kidID"] = kidID
        record["rewardID"] = rewardID
        record["dateCollected"] = dateCollected
        record["isDelivered"] = isDelivered
        
        // IMPORTANT: Preserve the kidReference for updates
        if let kidRef = kidReference {
            record["kidReference"] = kidRef
        }
        
        return record
    }
    
    init?(record: CKRecord) {
        print("🔧 INIT: Tentando criar CollectedReward do record: \(record.recordID.recordName)")
        print("🔧 INIT: Campos disponíveis: \(record.allKeys())")
        
        guard
            let kidID = record["kidID"] as? String,
            let rewardID = record["rewardID"] as? Int,
            let dateCollected = record["dateCollected"] as? Date,
            let isDelivered = record["isDelivered"] as? Bool else {
                
                print("🔧 INIT: ❌ Falha na conversão dos campos:")
                print("  - kidID: \(record["kidID"] ?? "nil") -> String? \(record["kidID"] as? String != nil ? "✅" : "❌")")
                print("  - rewardID: \(record["rewardID"] ?? "nil") -> Int? \(record["rewardID"] as? Int != nil ? "✅" : "❌")")
                print("  - dateCollected: \(record["dateCollected"] ?? "nil") -> Date? \(record["dateCollected"] as? Date != nil ? "✅" : "❌")")
                print("  - isDelivered: \(record["isDelivered"] ?? "nil") -> Bool? \(record["isDelivered"] as? Bool != nil ? "✅" : "❌")")
                
                return nil
        }
        
        print("🔧 INIT: ✅ Conversão bem-sucedida!")
        print("🔧 INIT: Dados convertidos:")
        print("  - kidID: \(kidID)")
        print("  - rewardID: \(rewardID)")
        print("  - dateCollected: \(dateCollected)")
        print("  - isDelivered: \(isDelivered)")
        
        self.id = record.recordID
        self.kidID = kidID
        self.rewardID = rewardID
        self.dateCollected = dateCollected
        self.isDelivered = isDelivered
        self.shareReference = record.share
        self.kidReference = record["kidReference"] as? CKRecord.Reference
        
        print("🔧 INIT: ✅ CollectedReward criado com sucesso!")
    }
}

// Equatable and Hashable extensions
extension CollectedReward: Equatable, Hashable {
    static func == (lhs: CollectedReward, rhs: CollectedReward) -> Bool {
        // If we have CloudKit IDs, compare those
        if let lhsID = lhs.id, let rhsID = rhs.id {
            return lhsID == rhsID
        }
        
        // Otherwise compare the content
        return lhs.localID == rhs.localID &&
            lhs.kidID == rhs.kidID &&
            lhs.rewardID == rhs.rewardID &&
            lhs.dateCollected == rhs.dateCollected &&
            lhs.isDelivered == rhs.isDelivered
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
        hasher.combine(rewardID)
        hasher.combine(dateCollected)
        hasher.combine(isDelivered)
    }
}
