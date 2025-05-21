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
    var collectedRewards = [CollectedReward]()
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
        coins -= amount
    }
}

// Extensão para tornar KidRecord Hashable e Equatable
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
        // Only create a new record if we don't have an existing ID
        guard id == nil else {
            return nil
        }
        
        // Create a record in the correct zone
        let newRecord = CKRecord(recordType: RecordType.kid.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidName"] = name
        newRecord["coins"] = coins
        
        return newRecord
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
