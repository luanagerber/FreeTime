//
//  Kid.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import Foundation
import CloudKit

struct Kid: Identifiable {
    var id: CKRecord.ID?
    var name: String
    var coins: Int
    
    // CloudKit related properties
    var shareReference: CKRecord.Reference?
    
    // Store the actual CKRecord for updates
    private var _record: CKRecord?
    
    init(name: String, coins: Int = 0) {
        self.name = name
        self.coins = coins
    }
    
    // Methods to manage coins
    mutating func addCoins(_ amount: Int) {
        coins += amount
        // Update the stored record if it exists
        if _record != nil {
            _record?["coins"] = coins
        }
    }
    
    mutating func removeCoins(_ amount: Int) {
        coins = max(0, coins - amount)
        // Update the stored record if it exists
        if _record != nil {
            _record?["coins"] = coins
        }
    }
}

// RecordProtocol extension
extension Kid: RecordProtocol {
    var record: CKRecord? {
        // Only create a new record if we don't have an ID
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.kid.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidName"] = name
        newRecord["coins"] = coins
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        // Return the stored record if available
        if let storedRecord = _record {
            // Ensure values are up to date
            storedRecord["kidName"] = name
            storedRecord["coins"] = coins
            return storedRecord
        }
        
        // Otherwise create a record with the existing ID
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.kid.rawValue, recordID: recordID)
        record["kidName"] = name
        record["coins"] = coins
        
        return record
    }
    
    init?(record: CKRecord) {
        guard let name = record["kidName"] as? String else {
            return nil
        }
        
        self.id = record.recordID
        self.name = name
        self.coins = record["coins"] as? Int ?? 0
        self.shareReference = record.share
        self._record = record // Store the actual record
    }
}

// Equatable and Hashable extensions
extension Kid: Equatable, Hashable {
    static func == (lhs: Kid, rhs: Kid) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.coins == rhs.coins
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coins)
    }
}

extension Kid {
    var pendingRewards: [Int] {
        get {
            associatedRecord?["pendingRewards"] as? [Int] ?? []
        }
        set {
            associatedRecord?["pendingRewards"] = newValue
        }
    }
    
    var deliveredRewards: [Int] {
        get {
            associatedRecord?["deliveredRewards"] as? [Int] ?? []
        }
        set {
            associatedRecord?["deliveredRewards"] = newValue
        }
    }
}
