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
    let activityID: UUID
    let date: Date
    let duration: TimeInterval
    var registerStatus: RegisterStatus
    
    // CloudKit related properties
    var shareReference: CKRecord.Reference?
    var kidReference: CKRecord.Reference? // Nova propriedade
        
    // For Identifiable conformance (UUID required if id is nil)
    private let localID = UUID()  // Luana que add
    
    init(kidID: String, activityID: UUID, date: Date, duration: TimeInterval, registerStatus: RegisterStatus = .notStarted) {
        self.kidID = kidID
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
    }
    
    init(kid: Kid, activityID: UUID, date: Date, duration: TimeInterval, registerStatus: RegisterStatus = .notStarted) {
        self.kidID = kid.id?.recordName ?? ""
        self.activityID = activityID
        self.date = date
        self.duration = duration
        self.registerStatus = registerStatus
        
        if let kidRecordID = kid.id {
            self.kidReference = CKRecord.Reference(recordID: kidRecordID, action: .deleteSelf)
        } //Qualquer coisa, o erro pode estar aqui kk
    }
    
    // Computed property to fetch the activity from the catalog
    var activity: Activity? {
        Activity.catalog.first { $0.id == activityID }
    }
}

// RecordProtocol extension
extension ActivitiesRegister: RecordProtocol {
    var record: CKRecord? {
        guard id == nil else { return nil }
        
        let newRecord = CKRecord(recordType: RecordType.activity.rawValue, zoneID: CloudConfig.recordZone.zoneID)
        newRecord["kidID"] = kidID // Salva o recordName como kidID
        newRecord["activityID"] = activityID.uuidString
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
           record["activityID"] = activityID.uuidString
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
        guard
            let kidID = record["kidID"] as? String,
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
        self.registerStatus = status
        self.shareReference = record.share
        self.kidReference = record["kidReference"] as? CKRecord.Reference
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
