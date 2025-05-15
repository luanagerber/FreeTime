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
    var kidID: UUID
    var activityID: UUID
    var date: Date
    var duration: TimeInterval
    var status: RegisterStatus
    var shareReference: CKRecord.Reference?
    
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.activity.rawValue)
        newRecord["kidID"] = kidID.uuidString
        newRecord["activityID"] = activityID.uuidString
        newRecord["date"] = date
        newRecord["duration"] = duration
        newRecord["status"] = status.rawValue
        
        return newRecord
    }
    
    var associatedRecord: CKRecord? {
        guard let recordID = id else { return nil }
        
        let record = CKRecord(recordType: RecordType.activity.rawValue, recordID: recordID)
        record["kidID"] = kidID.uuidString
        record["activityID"] = activityID.uuidString
        record["date"] = date
        record["duration"] = duration
        record["status"] = status.rawValue
        
        return record
    }
    
    init(register: Register) {
        self.kidID = register.kid.id
        self.activityID = register.activityID // Use the ID directly
        self.date = register.date
        self.duration = register.duration
        self.status = register.registerStatus
    }
    
    init?(record: CKRecord) {
        guard
            let kidIDString = record["kidID"] as? String,
            let kidID = UUID(uuidString: kidIDString),
            let activityIDString = record["activityID"] as? String,
            let activityID = UUID(uuidString: activityIDString),
            let date = record["date"] as? Date,
            let duration = record["duration"] as? TimeInterval,
            let statusRawValue = record["status"] as? Int,
            let status = RegisterStatus(rawValue: statusRawValue) else {
                return nil
        }
        
        self.id = record.recordID
        self.kidID = kidID
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.status = status
        self.shareReference = record["shareReference"] as? CKRecord.Reference
    }
}
