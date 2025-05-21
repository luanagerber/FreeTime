//
//  CloudConfig.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import CloudKit

enum CloudConfig {
    static let containerIndentifier = "iCloud.TesteFreeTime"
    static let recordZone: CKRecordZone = CKRecordZone(zoneName: "Kids")
    
    case privateDB
    case publicDB
    case sharedDB
}

enum RecordType: String {
    case kid = "Kid"
    case activity = "ScheduledActivity"
}

enum CloudError: Error {
    case recordZoneNotFound
    case resultInvalid
    case couldNotSave(Error)
    case recordNotFound
    case couldNotShareRecord
    case couldNotFetch(Error)
    case decodeError
    case kidNotCreated
    case activityNotCreated
    case couldNotDelete(Error)
}
