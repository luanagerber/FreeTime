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

struct KidRecord: RecordProtocol {
    var id: CKRecord.ID?
    var name: String
    var shareReference: CKRecord.Reference?
    
    var record: CKRecord? {
        // Neste ponto, só queremos criar um novo registro quando estamos adicionando um novo Kid
        // (não temos um ID existente)
        if id != nil {
            return nil
        }
        
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
