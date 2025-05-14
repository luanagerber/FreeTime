//
//  CKClient.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import CloudKit
import SwiftUI

protocol CKClient {
    func fetch<T: RecordProtocol>(recordType: String, dbType: CloudConfig, inZone: CKRecordZone.ID, predicate: NSPredicate?, completion: @escaping (Result<[T], CloudError>) -> Void)
    func save<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<T, CloudError>) -> Void)
    func modify<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<T, CloudError>) -> Void)
    func delete<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<Bool, CloudError>) -> Void)
    func share<T: RecordProtocol>(_ object: T, completion: @escaping (Result< any View, CloudError>)  -> Void) async throws
    func deleteShare<T: RecordProtocol>(_ object: T, completion: @escaping (Result<Void, CloudError>) -> Void) async
    func createZone(zone: CKRecordZone) async throws
}
