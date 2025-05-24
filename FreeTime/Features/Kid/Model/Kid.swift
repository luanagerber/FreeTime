//
//  Kid.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 06/05/25.
//

import Foundation
import CloudKit

struct Kid {
    var id: CKRecord.ID?
    let name: String
    var shareReference: CKRecord.Reference?
    var associatedRecord: CKRecord?
    
    private(set) var coins: Int
    
    init(name: String, coins: Int = 0) {
        self.name = name
        self.coins = coins
    }
    
    mutating func addCoins(_ amount: Int) {
        coins += amount
    }
    
    mutating func removeCoins(_ amount: Int) {
        coins = max(0, coins - amount) // Ensure coins never go negative
    }
}

// Extension to make Kid Hashable and Equatable
extension Kid: Hashable, Equatable {
    static func == (lhs: Kid, rhs: Kid) -> Bool {
        return lhs.id?.recordName == rhs.id?.recordName && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id?.recordName)
        hasher.combine(name)
    }
}

extension Kid: RecordProtocol {
    
    var record: CKRecord? {
        let recordToUpdate: CKRecord
        
        // Use existing record if available, otherwise create new one
        if let existingRecord = associatedRecord {
            recordToUpdate = existingRecord
        } else if let id = id {
            // Create record with existing ID (for updates)
            recordToUpdate = CKRecord(recordType: RecordType.kid.rawValue, recordID: id)
        } else {
            // Create completely new record
            recordToUpdate = CKRecord(recordType: RecordType.kid.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        }
        
        // Update fields
        recordToUpdate["kidName"] = name
        recordToUpdate["coins"] = coins
        
        return recordToUpdate
    }
    
    init?(record: CKRecord) {
        guard let name = record["kidName"] as? String,
              let coins = record["coins"] as? Int else {
            return nil
        }
        
        self.id = record.recordID
        self.name = name
        self.coins = coins
        self.shareReference = record.share
        self.associatedRecord = record
    }
}
