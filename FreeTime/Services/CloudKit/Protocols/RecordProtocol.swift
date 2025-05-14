//
//  RecordProtocol.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import CloudKit

protocol RecordProtocol {
    var record: CKRecord? { get }
    var associatedRecord: CKRecord? { get }
    init?(record: CKRecord)
}

struct KidRecord: RecordProtocol, Identifiable {
    var id: CKRecord.ID?
    var name: String
    var shareReference: CKRecord.Reference?
    
    init?(record: CKRecord) {
        guard record.recordType == RecordType.kid.rawValue,
              let kidName = record["kidName"] as? String else {
            return nil
        }
        
        self.id = record.recordID
        self.name = kidName
        self.shareReference = record["shareReference"] as? CKRecord.Reference
    }
    
    init(name: String) {
        self.name = name
    }
    
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.kid.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidName"] = name
        
        if let shareReference = shareReference {
            newRecord["shareReference"] = shareReference
        }
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        return nil
    }
}
