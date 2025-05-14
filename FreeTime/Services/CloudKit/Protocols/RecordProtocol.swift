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


struct ScheduledActivityRecord: RecordProtocol {
    var id: CKRecord.ID?
    var name: String
    var description: String
    var points: Int
    var type: String
    var isCompleted: Bool
    var shareReference: CKRecord.Reference?
    
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        // A zona será especificada quando o objeto for salvo usando o método save
        let newRecord = CKRecord(recordType: RecordType.activity.rawValue)
        newRecord["activityName"] = name
        newRecord["activityDescription"] = description
        newRecord["activityPoints"] = points
        newRecord["type"] = type
        newRecord["isCompleted"] = isCompleted
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.activity.rawValue, recordID: recordID)
        record["activityName"] = name
        record["activityDescription"] = description
        record["activityPoints"] = points
        record["type"] = type
        record["isCompleted"] = isCompleted
        
        return record
    }
    
    init(name: String, description: String, points: Int, type: String, isCompleted: Bool = false) {
        self.name = name
        self.description = description
        self.points = points
        self.type = type
        self.isCompleted = isCompleted
    }
    
    init?(record: CKRecord) {
        guard let name = record["activityName"] as? String,
              let description = record["activityDescription"] as? String,
              let points = record["activityPoints"] as? Int,
              let type = record["type"] as? String else {
            return nil
        }
        
        self.id = record.recordID
        self.name = name
        self.description = description
        self.points = points
        self.type = type
        self.isCompleted = record["isCompleted"] as? Bool ?? false
        self.shareReference = record.share
    }
}
