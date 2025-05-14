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
    
    func acceptSharing(shareMetadata: CKShare.Metadata, completion: @escaping (Bool) -> Void) {
        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
        container.accept(shareMetadata) { _, error in
            if let error = error {
                print("Error accepting share: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    // MARK: - Kid Operations
    
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
    
}
