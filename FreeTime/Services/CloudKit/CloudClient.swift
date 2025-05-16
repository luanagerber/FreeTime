//
//  CloudClient.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import CloudKit
import SwiftUI

final class CloudClient: CKClient {
    
    private var container: CKContainer = CKContainer(identifier: CloudConfig.containerIndentifier)
    
    func fetch<T: RecordProtocol>(recordType: String, dbType: CloudConfig =  CloudConfig.privateDB, inZone: CKRecordZone.ID, predicate: NSPredicate?, completion: @escaping (Result<[T], CloudError>) -> Void) {
        var recordsResult: [T] = []
        var database: CKDatabase
        
        switch dbType {
        case .privateDB:
            database = self.container.privateCloudDatabase
        case .publicDB:
            database = self.container.publicCloudDatabase
        case .sharedDB:
            database = self.container.sharedCloudDatabase
        }
        
        let query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: inZone) { matchResults in
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
    
    func save<T: RecordProtocol>(_ object: T, dbType: CloudConfig, inZone: CKRecordZone.ID, completion: @escaping (Result<T, CloudError>) -> Void) {
        var database: CKDatabase
        
        // Primeiro tentamos usar o método record do objeto
        if let record = object.record {
            // Se o record está disponível, precisamos garantir que ele esteja na zona correta
            // Como não podemos modificar o recordID, criamos um novo record na zona correta
            let newRecord = CKRecord(recordType: record.recordType, zoneID: inZone)
            
            // Copiamos todos os valores do record original para o novo
            for (key, value) in record.allKeys().map({ ($0, record[$0]) }) {
                if let value = value {
                    newRecord[key] = value
                }
            }
            
            switch dbType {
            case .privateDB:
                database = container.privateCloudDatabase
            case .publicDB:
                database = container.publicCloudDatabase
            case .sharedDB:
                database = container.sharedCloudDatabase
            }
            
            print("🔄 Salvando registro do tipo \(record.recordType) na zona \(inZone.zoneName)")
            
            database.save(newRecord) { result, error in
                if let error = error {
                    print("❌ Erro ao salvar registro: \(error.localizedDescription)")
                    completion(.failure(.couldNotSave(error)))
                    return
                }
                guard let result = result else {
                    print("❌ Resultado inválido ao salvar registro")
                    completion(.failure(.resultInvalid))
                    return
                }
                guard let record = T.init(record: result) else {
                    print("❌ Erro ao decodificar registro salvo")
                    completion(.failure(.decodeError))
                    return
                }
                print("✅ Registro salvo com sucesso")
                completion(.success(record))
            }
        } else {
            // Se não temos um record, provavelmente algo está errado com o objeto
            print("❌ Objeto não forneceu um registro válido")
            completion(.failure(.decodeError))
        }
    }
    
    func modify<T: RecordProtocol>(_ object: T, dbType: CloudConfig, inZone: CKRecordZone.ID, completion: @escaping (Result<T, CloudError>) -> Void) {
        var database: CKDatabase
        
        guard let record = object.associatedRecord else {
            completion(.failure(.decodeError))
            return
        }
        
        switch dbType {
        case .privateDB:
            database = container.privateCloudDatabase
        case .publicDB:
            database = container.publicCloudDatabase
        case .sharedDB:
            database = container.sharedCloudDatabase
        }
        database.save(record){ result, error in
            if let error {
                print(error)
                completion(.failure(.resultInvalid))
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
    
    func delete<T: RecordProtocol>(_ object: T, dbType: CloudConfig, inZone: CKRecordZone.ID, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        var database: CKDatabase
        
        // Garantir que o objeto tem um registro associado
        guard let record = object.associatedRecord else {
            completion(.failure(.decodeError))
            return
        }
        
        // Determinar qual banco de dados usar
        switch dbType {
        case .privateDB:
            database = container.privateCloudDatabase
        case .publicDB:
            database = container.publicCloudDatabase
        case .sharedDB:
            database = container.sharedCloudDatabase
        }
        
        database.delete(withRecordID: record.recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(.couldNotDelete(error)))
                return
            }
            
            // Se não houver erro, a deleção foi bem-sucedida
            completion(.success(true)) // Sucesso
        }
    }
    
    func share<T: RecordProtocol>(_ object: T, inZone: CKRecordZone.ID, completion: @escaping (Result<any View, CloudError>) ->  Void)  async throws{
        
        print("Iniciando compartilhamento")
        guard let record = object.associatedRecord else {
            completion(.failure(.recordNotFound))
            return
        }
        
        // Verificar se estamos trabalhando na zona correta
        if record.recordID.zoneID.zoneName != inZone.zoneName {
            print("⚠️ Aviso: O record não está na zona correta para compartilhamento")
            
        }
        
        guard let existingShare = record.share else {
            let share = CKShare(rootRecord: record)
            share[CKShare.SystemFieldKey.title] = "Compartilhando filho: \(record["kidName"] ?? "Unknown")"
            
            // Configurar permissões de compartilhamento explicitamente
            share.publicPermission = .readWrite
            
            // Salvar o registro e o compartilhamento juntos
            do {
                _ = try await container.privateCloudDatabase.modifyRecords(saving: [record, share], deleting: [])
                print("✅ Compartilhamento criado com sucesso")
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
                // Atualizar permissões de compartilhamento
                share.publicPermission = .readWrite
                
                // Salvar as alterações de permissão
                _ = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
                
                print("✅ Usando compartilhamento existente")
                completion(.success(CloudSharingView(share: share, container: container)))
            } else {
                completion(.failure(.couldNotShareRecord))
            }
        } catch {
            print("❌ Erro ao usar compartilhamento existente: \(error.localizedDescription)")
            completion(.failure(.couldNotShareRecord))
        }
    }
    
       // Método auxiliar para tentar obter o share atualizado várias vezes
       private func getUpdatedShare(_ shareID: CKRecord.ID) async throws -> CKShare {
           var attempts = 0
           let maxAttempts = 5
           
           while attempts < maxAttempts {
               do {
                   let share = try await container.privateCloudDatabase.record(for: shareID) as! CKShare
                   // Verificar se a URL está disponível
                   if share.url != nil {
                       return share
                   }
                   print("Tentativa \(attempts+1): Share obtido, mas URL ainda não está disponível")
               } catch {
                   print("Tentativa \(attempts+1) falhou: \(error.localizedDescription)")
               }
               
               attempts += 1
               try await Task.sleep(nanoseconds: 5_000_000_000) // 1 segundo
           }
           
           throw CloudError.couldNotShareRecord
       }
    
    func deleteShare<T: RecordProtocol>(_ object: T, completion: @escaping (Result<Void, CloudError>) -> Void) async {
        guard let record = object.associatedRecord, let share = record.share else {
            completion(.failure(.recordNotFound))
            return
        }
        
        let database = container.privateCloudDatabase
        
        do {
            try await database.deleteRecord(withID: share.recordID)
            
            completion(.success(()))
            
        } catch {
            completion(.failure(.couldNotDelete(error)))
        }
    }
    
    func createZone(zone: CKRecordZone) async throws {
        _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [zone], deleting: [])
    }
}
