//
//  CloudClient.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import CloudKit
import SwiftUI

final class CloudClient: CKClient {
    
    private var container: CKContainer = CKContainer(identifier: CloudConfig.containerIdentifier)
    
    func fetch<T: RecordProtocol>(recordType: String, dbType: CloudConfig = CloudConfig.privateDB, inZone: CKRecordZone.ID, predicate: NSPredicate?, completion: @escaping (Result<[T], CloudError>) -> Void) {
        var recordsResult: [T] = []
        var db: CKDatabase
        
        switch dbType {
        case .privateDB:
            db = self.container.privateCloudDatabase
        case .publicDB:
            db = self.container.publicCloudDatabase
        case .sharedDB:
            db = self.container.sharedCloudDatabase
        }
        
        let query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
        
        db.fetch(withQuery: query, inZoneWith: inZone) { matchResults in
            switch matchResults {
            case .success(let results):
                for result in results.matchResults {
                    switch result.1 {
                    case .success(let record):
                        guard let object = T.init(record: record) else {
                            completion(.failure(.decodeError))
                            return
                        }
                        recordsResult.append(object)
                    case .failure(let error):
                        completion(.failure(.couldNotFetch(error)))
                        return
                    }
                }
                
            case .failure(let error):
                completion(.failure(.couldNotFetch(error)))
                return
            }
            completion(.success(recordsResult))
        }
    }
    
    /*
    //MARK: SUGESTÃO
    private func database(for config: CloudConfig) -> CKDatabase {
        switch config {
        case .privateDB:
            return container.privateCloudDatabase
        case .publicDB:
            return container.publicCloudDatabase
        case .sharedDB:
            return container.sharedCloudDatabase
        }
    }
     */

    func save<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<T, CloudError>) -> Void) {
        var db: CKDatabase
        
        guard let record = object.record else {
            completion(.failure(.decodeError))
            return
        }
        #warning("Em todas as funções está passando o mesmo switch. Sugestão: Criar um método que implementa o switch.")

//      let dbType = database(for: dbType)
        
        switch dbType {
        case .privateDB:
            db = container.privateCloudDatabase
        case .publicDB:
            db = container.publicCloudDatabase
        case .sharedDB:
            db = container.sharedCloudDatabase
        }
        
        db.save(record) { result, error in
            if let error {
                completion(.failure(.couldNotSave(error)))
                return
            }
            guard let result else {
                completion(.failure(.resultInvalid))
                return
            }
            guard let record = T.init(record: result) else {
                completion(.failure(.decodeError))
                return
            }
            completion(.success(record))
        }
    }
    
    func modify<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<T, CloudError>) -> Void) {
        var db: CKDatabase
        
        guard let record = object.associatedRecord else {
            completion(.failure(.decodeError))
            return
        }
        
        switch dbType {
        case .privateDB:
            db = container.privateCloudDatabase
        case .publicDB:
            db = container.publicCloudDatabase
        case .sharedDB:
            db = container.sharedCloudDatabase
        }
        db.save(record){ result, error in
            if let error {
                print(error)
                completion(.failure(.resultInvalid))
                return
            }
            if let result {
                guard let result = T.init(record: result) else {
                    completion(.failure(.decodeError))
                    return
                }
                completion(.success(result))
            }
        }
    }
    
    func delete<T: RecordProtocol>(_ object: T, dbType: CloudConfig, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        var db: CKDatabase
        
        // Garantir que o objeto tem um registro associado
        guard let record = object.associatedRecord else {
            completion(.failure(.decodeError))
            return
        }
        
        // Determinar qual banco de dados usar
        switch dbType {
        case .privateDB:
            db = container.privateCloudDatabase
        case .publicDB:
            db = container.publicCloudDatabase
        case .sharedDB:
            db = container.sharedCloudDatabase
        }
        
        db.delete(withRecordID: record.recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(.couldNotDelete(error)))
                return
            }
            
            // Se não houver erro, a deleção foi bem-sucedida
            completion(.success(true)) // Sucesso
        }
    }
    
    func share<T: RecordProtocol>(_ object: T, completion: @escaping (Result<any View, CloudError>) -> Void) async throws {
        guard let record = object.associatedRecord else {
            completion(.failure(.recordNotFound))
            return
        }
        
        guard let existingShare = record.share else {
            let share = CKShare(rootRecord: record)
            share[CKShare.SystemFieldKey.title] = "Compartilhando filho: \(record["kidName"] ?? "Unknown")"
            share.publicPermission = .readWrite
            
            do {
                _ = try await container.privateCloudDatabase.modifyRecords(saving: [record, share], deleting: [])
                completion(.success(CloudSharingView(share: share, container: container)))
            } catch {
                print("❌ Erro ao criar compartilhamento: \(error.localizedDescription)")
                completion(.failure(.couldNotShareRecord))
            }
            
            return
        }
        
        do {
            let share = try await container.privateCloudDatabase.record(for: existingShare.recordID) as? CKShare
            if let share = share {
                share.publicPermission = .readWrite
                _ = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
                completion(.success(CloudSharingView(share: share, container: container)))
            } else {
                completion(.failure(.couldNotShareRecord))
            }
        } catch {
            print("❌ Erro ao usar compartilhamento existente: \(error.localizedDescription)")
            completion(.failure(.couldNotShareRecord))
        }
    }
    
    func deleteShare<T: RecordProtocol>(_ object: T, completion: @escaping (Result<Void, CloudError>) -> Void) async {
        guard let record = object.associatedRecord, let share = record.share else {
            completion(.failure(.recordNotFound))
            return
        }
        
        let db = container.privateCloudDatabase
        
        do {
            try await db.deleteRecord(withID: share.recordID)
            completion(.success(()))
        } catch {
            completion(.failure(.couldNotDelete(error)))
        }
    }
    
    func createZone(zone: CKRecordZone) async throws {
        _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [zone], deleting: [])
    }
}
