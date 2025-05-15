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
    private var currentZone: CKRecordZone?
        
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
    
    func createZoneIfNeeded(zoneName: String = "Kids") async throws -> CKRecordZone {
        print("📁 Tentando criar/obter zona: \(zoneName)")
        
        // Verifica se a zona já existe antes de criar
        if let existingZone = await checkIfZoneExists(zoneName: zoneName) {
            print("✅ Zona existente encontrada: \(existingZone.zoneID.zoneName)")
            self.currentZone = existingZone
            return existingZone
        }
        
        print("🆕 Criando nova zona: \(zoneName)")
        // Se não existe, cria uma nova zona
        let newZone = CloudConfig.createCustomZone(withName: zoneName)
        
        do {
            try await client.createZone(zone: newZone)
            print("✅ Zona criada com sucesso: \(newZone.zoneID.zoneName)")
            self.currentZone = newZone
            return newZone
        } catch {
            print("❌ ERRO: Falha ao criar zona personalizada: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func checkIfZoneExists(zoneName: String) async -> CKRecordZone? {
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        
        do {
            let zones = try await container.privateCloudDatabase.allRecordZones()
            print("🔍 Zonas existentes: \(zones.map { $0.zoneID.zoneName })")
            return zones.first { $0.zoneID.zoneName == zoneName }
        } catch {
            print("❌ ERRO: Falha ao verificar zonas existentes: \(error.localizedDescription)")
            return nil
        }
    }

    
    // MARK: - Kid Operations
    // @ Tete, alterei essas funções pra elas se adequarem a organização do código do projeto, com KidRecord no lugar de Kid.
    
    func createKid(_ kid: KidRecord, completion: @escaping (Result<KidRecord, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Save the KidRecord in the private database
        client.save(kid, dbType: .privateDB) { result in
            completion(result)
        }
    }
    
    func fetchKids(completion: @escaping (Result<[KidRecord], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        client.fetch(
            recordType: RecordType.kid.rawValue,
            dbType: .privateDB,
            inZone: kidsZone.zoneID,
            predicate: nil
        ) { (result: Result<[KidRecord], CloudError>) in
            completion(result)
        }
    }
    
    func shareKid(_ kid: KidRecord, completion: @escaping (Result<any View, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        do {
            try await client.share(kid, completion: completion)
        } catch {
            print("Error sharing kid: \(error)")
            completion(.failure(.couldNotShareRecord))
        }
    }
    
    func updateKid(_ kid: KidRecord, completion: @escaping (Result<KidRecord, CloudError>) -> Void) {
        client.modify(kid, dbType: .privateDB) { result in
            completion(result)
        }
    }
    
    func deleteKid(_ kid: KidRecord, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        client.delete(kid, dbType: .privateDB) { result in
            completion(result)
        }
    }
    
    func deleteKidShare(_ kid: KidRecord, completion: @escaping (Result<Void, CloudError>) -> Void) async {
        await client.deleteShare(kid, completion: completion)
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
    
//    func acceptSharing(shareMetadata: CKShare.Metadata, completion: @escaping (Bool) -> Void) {
//        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
//        container.accept(shareMetadata) { _, error in
//            if let error = error {
//                print("Error accepting share: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//            completion(true)
//        }
//    }
    
    // MARK: - Shared Content Handling
    // @ Tete, essas funções são novas, usam apenas a zona Kids
    func acceptSharedKid(shareMetadata: CKShare.Metadata, completion: @escaping (Result<KidRecord, CloudError>) -> Void) {
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        
        container.accept(shareMetadata) { _, error in
            if let error = error {
                print("Error accepting share: \(error.localizedDescription)")
                completion(.failure(.couldNotShareRecord))
                return
            }
            
            // After accepting the share, fetch the shared kid record
            Task {
                do {
                    let sharedZone = try await self.createZoneIfNeeded(zoneName: "Kids")
                    
                    // Create a predicate to find the specific shared record
                    let predicate = NSPredicate(format: "recordID == %@", shareMetadata.rootRecordID)
                    
                    self.client.fetch(
                        recordType: RecordType.kid.rawValue,
                        dbType: .sharedDB,
                        inZone: sharedZone.zoneID,
                        predicate: predicate
                    ) { (result: Result<[KidRecord], CloudError>) in
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
                } catch {
                    completion(.failure(.couldNotFetch(error as NSError)))
                }
            }
        }
    }
    
    // MARK: - Activity Operations
    // @ Tete, essas funções são novas, usam apenas a zona Kids e usam a KidId como chave de referência.
    
    //    Complete Flow:
    //    1. When you create a KidRecord, it gets a unique UUID
    //    2. When you create activities for that kid, you set the kidID field to the kid's UUID
    //    3. When you share the KidRecord with another user:
    //    3.1. They receive access to the kid's data
    //    3.2. They can fetch all activities with the matching kidID
    //    3.3. They can add, update, or delete activities linked to that kid
    

    func createActivity(_ activity: ScheduledActivityRecord, completion: @escaping (Result<ScheduledActivityRecord, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Save the activity in the private database
        client.save(activity, dbType: .privateDB) { result in
            completion(result)
        }
    }

    func fetchActivities(forKid kidID: UUID, completion: @escaping (Result<[ScheduledActivityRecord], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Create a predicate to filter activities by kidID
        let predicate = NSPredicate(format: "kidID == %@", kidID.uuidString)
        
        client.fetch(
            recordType: RecordType.activity.rawValue,
            dbType: .privateDB,
            inZone: kidsZone.zoneID,
            predicate: predicate
        ) { (result: Result<[ScheduledActivityRecord], CloudError>) in
            completion(result)
        }
    }

    func fetchSharedActivities(forKid kidID: UUID, completion: @escaping (Result<[ScheduledActivityRecord], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Create a predicate to filter activities by kidID
        let predicate = NSPredicate(format: "kidID == %@", kidID.uuidString)
        
        // When fetching shared activities, we use the sharedDB
        client.fetch(
            recordType: RecordType.activity.rawValue,
            dbType: .sharedDB,
            inZone: kidsZone.zoneID,
            predicate: predicate
        ) { (result: Result<[ScheduledActivityRecord], CloudError>) in
            completion(result)
        }
    }

    func updateActivity(_ activity: ScheduledActivityRecord, completion: @escaping (Result<ScheduledActivityRecord, CloudError>) -> Void) {
        // Determine which database to use based on whether the activity is shared
        let dbType: CloudConfig = activity.shareReference != nil ? .sharedDB : .privateDB
        
        client.modify(activity, dbType: dbType) { result in
            completion(result)
        }
    }

    func deleteActivity(_ activity: ScheduledActivityRecord, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        // Determine which database to use based on whether the activity is shared
        let dbType: CloudConfig = activity.shareReference != nil ? .sharedDB : .privateDB
        
        client.delete(activity, dbType: dbType) { result in
            completion(result)
        }
    }

    // For fetching all activities (both owned and shared)
    func fetchAllActivities(forKid kidID: UUID, completion: @escaping (Result<[ScheduledActivityRecord], CloudError>) -> Void) async throws {
        var allActivities: [ScheduledActivityRecord] = []
        var fetchError: CloudError? = nil
        
        let group = DispatchGroup()
        
        // Fetch private activities
        group.enter()
        try await fetchActivities(forKid: kidID) { result in
            switch result {
            case .success(let activities):
                allActivities.append(contentsOf: activities)
            case .failure(let error):
                fetchError = error
            }
            group.leave()
        }
        
        // Fetch shared activities
        group.enter()
        try await fetchSharedActivities(forKid: kidID) { result in
            switch result {
            case .success(let activities):
                allActivities.append(contentsOf: activities)
            case .failure(let error):
                if fetchError == nil {
                    fetchError = error
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(allActivities))
            }
        }
    }
    
}
