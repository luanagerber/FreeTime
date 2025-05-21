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
