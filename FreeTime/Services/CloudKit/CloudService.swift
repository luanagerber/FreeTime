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
        let newZone = CKRecordZone(zoneName: zoneName)
        
        do {
            try await client.createZone(zone: newZone)
            print("✅ Zona criada com sucesso: \(newZone.zoneID.zoneName)")
            self.currentZone = newZone
            
            // Após criar a zona, precisamos configurá-la para permitir compartilhamento
            // Isso deve ser feito configurando a permissão de compartilhamento ao criar um CKShare
            
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
    
    func createKid(_ kid: KidRecord, completion: @escaping (Result<KidRecord, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔄 Tentando criar kid na zona: \(kidsZone.zoneID.zoneName)")
        
        // Modificamos aqui para especificar a zona Kids ao salvar o KidRecord
        client.save(kid, dbType: .privateDB, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }
    
    func fetchKids(completion: @escaping (Result<[KidRecord], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔍 Buscando kids na zona: \(kidsZone.zoneID.zoneName)")
        
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
        
        print("🔄 Tentando compartilhar kid: \(kid.name) na zona: \(kidsZone.zoneID.zoneName)")
        
        do {
            try await client.share(kid, inZone: kidsZone.zoneID, completion: completion)
        } catch {
            print("❌ Erro ao compartilhar kid: \(error)")
            completion(.failure(.couldNotShareRecord))
        }
    }
    
//    func shareKid(_ kid: KidRecord, completion: @escaping (Result<UICloudSharingController, CloudError>) -> Void) async throws {
//        // Ensure the Kids zone exists
//        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
//        
//        print("🔄 Tentando compartilhar kid: \(kid.name) na zona: \(kidsZone.zoneID.zoneName)")
//        
//        try await client.share(kid, inZone: kidsZone.zoneID, completion: completion)
//    }
    
    func updateKid(_ kid: KidRecord, completion: @escaping (Result<KidRecord, CloudError>) -> Void) async throws {
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔄 Atualizando kid: \(kid.name) na zona: \(kidsZone.zoneID.zoneName)")
        
        client.modify(kid, dbType: .privateDB, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }
    
    func deleteKid(_ kid: KidRecord, completion: @escaping (Result<Bool, CloudError>) -> Void) async throws {
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🗑️ Deletando kid: \(kid.name) na zona: \(kidsZone.zoneID.zoneName)")
        
        client.delete(kid, dbType: .privateDB, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }
    
    func deleteKidShare(_ kid: KidRecord, completion: @escaping (Result<Void, CloudError>) -> Void) async {
        print("🗑️ Removendo compartilhamento para kid: \(kid.name)")
        
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
    
    // MARK: - Shared Content Handling
    func acceptSharedKid(shareMetadata: CKShare.Metadata, completion: @escaping (Result<KidRecord, CloudError>) -> Void) {
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        
        print("🔄 Aceitando compartilhamento...")
        
        container.accept(shareMetadata) { _, error in
            if let error = error {
                print("❌ Erro ao aceitar compartilhamento: \(error.localizedDescription)")
                completion(.failure(.couldNotShareRecord))
                return
            }
            
            print("✅ Compartilhamento aceito, buscando registro compartilhado...")
            
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
                                print("✅ Registro compartilhado encontrado: \(kid.name)")
                                completion(.success(kid))
                            } else {
                                print("❌ Nenhum registro compartilhado encontrado")
                                completion(.failure(.recordNotFound))
                            }
                        case .failure(let error):
                            print("❌ Erro ao buscar registro compartilhado: \(error)")
                            completion(.failure(error))
                        }
                    }
                } catch {
                    print("❌ Erro: \(error.localizedDescription)")
                    completion(.failure(.couldNotFetch(error as NSError)))
                }
            }
        }
    }
    
    // MARK: - Métodos genéricos para Records
    
    func createRecord<T: RecordProtocol>(_ record: T, inRecordType recordType: String, completion: @escaping (Result<T, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔄 Criando registro do tipo \(recordType) na zona: \(kidsZone.zoneID.zoneName)")
        
        // Save the record in the private database
        client.save(record, dbType: .privateDB, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }

    func fetchRecords<T: RecordProtocol>(ofType recordType: String, withPredicate predicate: NSPredicate? = nil, completion: @escaping (Result<[T], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔍 Buscando registros do tipo \(recordType) na zona: \(kidsZone.zoneID.zoneName)")
        
        client.fetch(
            recordType: recordType,
            dbType: .privateDB,
            inZone: kidsZone.zoneID,
            predicate: predicate
        ) { (result: Result<[T], CloudError>) in
            completion(result)
        }
    }

    func fetchSharedRecords<T: RecordProtocol>(ofType recordType: String, withPredicate predicate: NSPredicate? = nil, completion: @escaping (Result<[T], CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        print("🔍 Buscando registros compartilhados do tipo \(recordType) na zona: \(kidsZone.zoneID.zoneName)")
        
        client.fetch(
            recordType: recordType,
            dbType: .sharedDB,
            inZone: kidsZone.zoneID,
            predicate: predicate
        ) { (result: Result<[T], CloudError>) in
            completion(result)
        }
    }

    func updateRecord<T: RecordProtocol>(_ record: T, isShared: Bool = false, completion: @escaping (Result<T, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Determine which database to use based on whether the record is shared
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        
        print("🔄 Atualizando registro na zona: \(kidsZone.zoneID.zoneName), banco: \(dbType)")
        
        client.modify(record, dbType: dbType, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }

    func deleteRecord<T: RecordProtocol>(_ record: T, isShared: Bool = false, completion: @escaping (Result<Bool, CloudError>) -> Void) async throws {
        // Ensure the Kids zone exists
        let kidsZone = try await createZoneIfNeeded(zoneName: "Kids")
        
        // Determine which database to use based on whether the record is shared
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        
        print("🗑️ Deletando registro na zona: \(kidsZone.zoneID.zoneName), banco: \(dbType)")
        
        client.delete(record, dbType: dbType, inZone: kidsZone.zoneID) { result in
            completion(result)
        }
    }
    
    // MARK: - Métodos de conveniência para atividades
    // Estes métodos são adaptadores para manter compatibilidade com o código existente
    
    func createActivity<T: RecordProtocol>(_ activity: T, completion: @escaping (Result<T, CloudError>) -> Void) async throws {
        try await createRecord(activity, inRecordType: RecordType.activity.rawValue, completion: completion)
    }

    func fetchActivities<T: RecordProtocol>(forKid kidID: UUID, completion: @escaping (Result<[T], CloudError>) -> Void) async throws {
        let predicate = NSPredicate(format: "kidID == %@", kidID.uuidString)
        try await fetchRecords(ofType: RecordType.activity.rawValue, withPredicate: predicate, completion: completion)
    }

    func fetchSharedActivities<T: RecordProtocol>(forKid kidID: UUID, completion: @escaping (Result<[T], CloudError>) -> Void) async throws {
        let predicate = NSPredicate(format: "kidID == %@", kidID.uuidString)
        try await fetchSharedRecords(ofType: RecordType.activity.rawValue, withPredicate: predicate, completion: completion)
    }

    func updateActivity<T: RecordProtocol>(_ activity: T, isShared: Bool, completion: @escaping (Result<T, CloudError>) -> Void) async throws {
        try await updateRecord(activity, isShared: isShared, completion: completion)
    }

    func deleteActivity<T: RecordProtocol>(_ activity: T, isShared: Bool, completion: @escaping (Result<Bool, CloudError>) -> Void) async throws {
        try await deleteRecord(activity, isShared: isShared, completion: completion)
    }
    
    // Método auxiliar para buscar todas as atividades (privadas e compartilhadas)
    func fetchAllActivities<T: RecordProtocol>(forKid kidID: UUID, completion: @escaping (Result<[T], CloudError>) -> Void) async throws {
        var allActivities: [T] = []
        var fetchError: CloudError? = nil
        
        let group = DispatchGroup()
        
        // Busca atividades privadas
        group.enter()
        try await fetchActivities(forKid: kidID) { (result: Result<[T], CloudError>) in
            switch result {
            case .success(let activities):
                allActivities.append(contentsOf: activities)
            case .failure(let error):
                fetchError = error
            }
            group.leave()
        }
        
        // Busca atividades compartilhadas
        group.enter()
        try await fetchSharedActivities(forKid: kidID) { (result: Result<[T], CloudError>) in
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
        
        // Quando ambas as buscas terminarem
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(allActivities))
            }
        }
    }
}
