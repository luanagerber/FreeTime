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

// @Tete, Kid virou KidRecord
struct KidRecord: RecordProtocol {
    var id: CKRecord.ID?
    var name: String
    var shareReference: CKRecord.Reference?
    
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.kid.rawValue)
        newRecord["kidName"] = name
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.kid.rawValue, recordID: recordID)
        record["kidName"] = name
        
        return record
    }
    
    init(name: String) {
        self.name = name
    }
    
    init?(record: CKRecord) {
        guard let name = record["kidName"] as? String else {
            return nil
        }
        
        self.id = record.recordID
        self.name = name
        self.shareReference = record.share
    }
}

// @Tete, Activity virou ScheduledActivityRecord
struct ScheduledActivityRecord: RecordProtocol {
    var id: CKRecord.ID?
    var name: String
    var description: String
    var points: Int
    var type: String
    var status: Bool
    var shareReference: CKRecord.Reference?
    
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        // A zona será especificada quando o objeto for salvo usando o método save
        let newRecord = CKRecord(recordType: RecordType.activity.rawValue)
        newRecord["activityName"] = name
        newRecord["activityDescription"] = description
        newRecord["activityPoints"] = points
        newRecord["type"] = type
        newRecord["status"] = status
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.activity.rawValue, recordID: recordID)
        record["activityName"] = name
        record["activityDescription"] = description
        record["activityPoints"] = points
        record["type"] = type
        record["status"] = status
        
        return record
    }
    
    init(name: String, description: String, points: Int, type: String, isCompleted: Bool = false) {
        self.name = name
        self.description = description
        self.points = points
        self.type = type
        self.status = isCompleted
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
        self.status = record["isCompleted"] as? Bool ?? false
        self.shareReference = record.share
    }
}
