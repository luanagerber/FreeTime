//
//  CloudService.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import CloudKit
import SwiftUI

final class CloudService {
    private let client: CKClient
    
    init(client: CKClient = CloudClient()) {
        self.client = client
        checkCloudStatus()
    }
    
    static let shared = CloudService()

    // MARK: - Cloud Status

    private func checkCloudStatus() {
        CKContainer(identifier: CloudConfig.containerIndentifier).accountStatus { (status, error) in
            if let error = error {
                print("❌ Erro ao verificar status do CloudKit: \(error.localizedDescription)")
            } else {
                switch status {
                case .available:
                    print("✅ CloudKit disponível - status: \(status)")
                case .noAccount:
                    print("❌ Sem conta iCloud - status: \(status)")
                case .restricted:
                    print("⚠️ Acesso ao CloudKit restrito - status: \(status)")
                case .couldNotDetermine:
                    print("❓ Não foi possível determinar o status do CloudKit - status: \(status)")
                case .temporarilyUnavailable:
                    print("temporarily Unavailable")
                @unknown default:
                    print("❓ Status do CloudKit desconhecido: \(status)")
                }
            }
        }
    }
    
    
    // MARK: - Zone Management
    
    func createZoneIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: "isZoneCreated") else {
            return
        }
        
        do {
            try await client.createZone(zone: CloudConfig.recordZone)
            print("✅ Zona criada com sucesso")
            UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
        } catch {
            print("❌ ERRO: Falha ao criar zona personalizada: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Kid Operations
    
    func saveKid(_ kid: Kid, completion: @escaping (Result<Kid, CloudError>) -> Void) {
        client.save(kid, dbType: .privateDB, completion: completion)
    }
    
    func fetchKid(withRecordID recordID: CKRecord.ID, completion: @escaping (Result<Kid, CloudError>) -> Void) {
        let predicate = NSPredicate(format: "recordID == %@", recordID)
        
        client.fetch(
            recordType: RecordType.kid.rawValue,
            dbType: .sharedDB,
            inZone: recordID.zoneID,
            predicate: predicate
        ) { (result: Result<[Kid], CloudError>) in
            switch result {
            case .success(let kids):
                if let kid = kids.first {
                    completion(.success(kid))
                } else {
                    completion(.failure(.recordNotFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllKids(completion: @escaping (Result<[Kid], CloudError>) -> Void) {
        client.fetch(
            recordType: RecordType.kid.rawValue,
            dbType: .privateDB,
            inZone: CloudConfig.recordZone.zoneID,
            predicate: nil
        ) { (result: Result<[Kid], CloudError>) in
            switch result {
            case .success(let kids):
                let sortedKids = kids.sorted {
                    ($0.associatedRecord?.creationDate ?? Date()) < ($1.associatedRecord?.creationDate ?? Date())
                }
                completion(.success(sortedKids))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteKid(_ kid: Kid, completion: @escaping (Result<Void, CloudError>) -> Void) {
        Task {
            guard let record = kid.associatedRecord else {
                completion(.failure(.recordNotFound))
                return
            }
            
            // Deletes the associated share with the record (if it exists)
            if record.share != nil {
                print("Kid does have a share, removing it...")
                await client.deleteShare(kid) { shareResult in
                    switch shareResult {
                    case .success:
                        print("CKShare removed with success")
                    case .failure(let error):
                        print("Failed removing CKShare:", error)
                        completion(.failure(error))
                        return
                    }
                }
            }
            
            // Deletes the record
            client.delete(kid, dbType: .privateDB) { result in
                switch result {
                case .success:
                    print("Kid deleted")
                    completion(.success(()))
                case .failure(let error):
                    print("Kid deletion failed:", error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Activity Operations
    
    func saveActivity(_ activity: ActivitiesRegister, completion: @escaping (Result<ActivitiesRegister, CloudError>) -> Void) {
        client.save(activity, dbType: .privateDB, completion: completion)
    }
    
    func fetchAllActivities(forKid kidID: String, completion: @escaping (Result<[ActivitiesRegister], CloudError>) -> Void) {
        let predicate = NSPredicate(format: "kidID == %@", kidID)
        
        client.fetch(
            recordType: RecordType.activity.rawValue,
            dbType: .privateDB,
            inZone: CloudConfig.recordZone.zoneID,
            predicate: predicate
        ) { (result: Result<[ActivitiesRegister], CloudError>) in
            switch result {
            case .success(let activities):
                let sortedActivities = activities.sorted {
                    $0.date < $1.date
                }
                completion(.success(sortedActivities))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchSharedActivities(forKid kidID: String, completion: @escaping (Result<[ActivitiesRegister], CloudError>) -> Void) {
        guard let rootRecordID = getRootRecordID() else {
            completion(.failure(.kidNotCreated))
            return
        }
        
        let predicate = NSPredicate(format: "kidID == %@", kidID)
        
        client.fetch(
            recordType: RecordType.activity.rawValue,
            dbType: .sharedDB,
            inZone: rootRecordID.zoneID,
            predicate: predicate
        ) { (result: Result<[ActivitiesRegister], CloudError>) in
            switch result {
            case .success(let activities):
                let sortedActivities = activities.sorted {
                    $0.date < $1.date
                }
                completion(.success(sortedActivities))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateActivity(_ activity: ActivitiesRegister, isShared: Bool, completion: @escaping (Result<ActivitiesRegister, CloudError>) -> Void) {
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        client.modify(activity, dbType: dbType, completion: completion)
    }
    
    func deleteActivity(_ activity: ActivitiesRegister, isShared: Bool, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        client.delete(activity, dbType: dbType, completion: completion)
    }
    
    // MARK: - Sharing Operations
    
    func shareKid(_ kid: Kid, completion: @escaping (Result<any View, CloudError>) -> Void) async throws {
        try await client.share(kid, completion: completion)
    }
    
    // MARK: - Utility Methods
    
    func checkSharingStatus(completion: @escaping (Bool) -> Void) {
        CKContainer(identifier: CloudConfig.containerIndentifier).accountStatus { status, error in
            if let error = error {
                print("Error checking iCloud status: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(status == .available)
        }
    }
}

extension CloudService {
    func saveRootRecordID(_ recordID: CKRecord.ID) {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: recordID, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: "rootRecordID")
    }
    
    func getRootRecordID() -> CKRecord.ID? {
        guard let data = UserDefaults.standard.data(forKey: "rootRecordID"),
              let recordID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: data) else {
            return nil
        }
        return recordID
    }
}
