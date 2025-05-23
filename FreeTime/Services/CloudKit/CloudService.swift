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
    
    private var container: CKContainer {
        return CKContainer(identifier: CloudConfig.containerIdentifier)
    }
    
    
    // MARK: - CloudKit Configuration & Status
    
    private func checkCloudStatus() {
        CKContainer(identifier: CloudConfig.containerIdentifier).accountStatus { (status, error) in
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
    
    func createZoneIfNeeded() async throws {
        print("📁 Tentando verificar a zona Kids")
        
        // Primeiro, vamos verificar se a zona já existe
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        
        do {
            // Tentar listar todas as zonas existentes
            let zones = try await container.privateCloudDatabase.allRecordZones()
            print("🔍 Zonas existentes: \(zones.map { $0.zoneID.zoneName })")
            
            // Verificar se a zona Kids já existe
            if zones.contains(where: { $0.zoneID.zoneName == "Kids" }) {
                print("✅ Zona Kids já existe")
                return
            }
            
            // Se chegou aqui, a zona não existe e precisamos criá-la
            print("🆕 Zona Kids não existe, criando...")
            
            // Criar a zona
            let newZone = CKRecordZone(zoneName: "Kids")
            try await container.privateCloudDatabase.modifyRecordZones(saving: [newZone], deleting: [])
            
            // Verificar se a zona foi criada com sucesso
            let updatedZones = try await container.privateCloudDatabase.allRecordZones()
            if updatedZones.contains(where: { $0.zoneID.zoneName == "Kids" }) {
                print("✅ Zona Kids criada com sucesso")
                
                // Atualizar a configuração global
                UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
            } else {
                print("❌ Falha ao criar zona Kids - não encontrada após criação")
                throw CloudError.recordZoneNotFound
            }
        } catch {
            print("❌ Erro ao criar/verificar zona Kids: \(error.localizedDescription)")
            throw error
        }
    }
    
    func checkSharingStatus(completion: @escaping (Bool) -> Void) {
        CKContainer(identifier: CloudConfig.containerIdentifier).accountStatus { status, error in
            if let error = error {
                print("Error checking iCloud status: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(status == .available)
        }
    }
    
    
    // MARK: - Kid Operations (Create/Read/Delete)
    
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
    
    //TODO: Provavelmente deletar depois
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
    
    
    // MARK: - Kid Sharing Operations
    
    func shareKid(_ kid: Kid, completion: @escaping (Result<any View, CloudError>) -> Void) async throws {
        guard let record = kid.associatedRecord else {
            print("COMPARTILHAMENTO: Falha - registro associado da criança é nulo")
            completion(.failure(.recordNotFound))
            return
        }
        
        // Acessar o container diretamente
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let privateDB = container.privateCloudDatabase
        
        // Verificar se já existe um compartilhamento
        if let existingShare = record.share {
            print("COMPARTILHAMENTO: Usando compartilhamento existente para \(record["kidName"] ?? "Unknown")")
            
            do {
                let share = try await privateDB.record(for: existingShare.recordID) as? CKShare
                if let share = share {
                    // Atualizar permissões
                    share.publicPermission = CKShare.ParticipantPermission.readWrite
                    
                    // Buscar atividades relacionadas para recompartilhar
                    let kidName = record.recordID.recordName
                    print("COMPARTILHAMENTO: Buscando atividades para recompartilhar com Kid ID: \(kidName)")
                    
                    let activities = try await fetchRelatedActivities(kidName: kidName)
                    print("COMPARTILHAMENTO: Encontradas \(activities.count) atividades para compartilhar")
                    
                    for (index, activity) in activities.enumerated() {
                        print("COMPARTILHAMENTO: Atividade \(index): ID=\(activity.activityID), Data=\(activity.date)")
                    }
                    
                    // NOVA ABORDAGEM: Configurar hierarquia pai-filho explícita
                    print("COMPARTILHAMENTO: Configurando hierarquia pai-filho para compartilhamento...")
                    
                    // 1. Primeiro atualizar o Kid e Share
                    do {
                        let (kidResults, _) = try await privateDB.modifyRecords(saving: [record, share], deleting: [])
                        print("COMPARTILHAMENTO: ✅ Kid e Share atualizados: \(kidResults.count)")
                    } catch {
                        print("COMPARTILHAMENTO: ⚠️ Erro ao atualizar Kid/Share (continuando): \(error)")
                    }
                    
                    // 2. Configurar cada atividade como FILHA do Kid
                    var successCount = 0
                    for (index, activity) in activities.enumerated() {
                        if let activityRecord = activity.associatedRecord {
                            print("COMPARTILHAMENTO: Configurando atividade \(index + 1)/\(activities.count) como filha...")
                            
                            // CONFIGURAR HIERARQUIA PAI-FILHO EXPLÍCITA
                            activityRecord.setParent(record)
                            
                            // Manter a kidReference também para busca
                            activityRecord["kidReference"] = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
                            
                            // Garantir que todos os campos estão corretos
                            activityRecord["kidID"] = kidName
                            
                            print("COMPARTILHAMENTO: - Parent configurado: \(activityRecord.parent?.recordID.recordName ?? "nil")")
                            print("COMPARTILHAMENTO: - kidReference: \(activityRecord["kidReference"] != nil)")
                            print("COMPARTILHAMENTO: - kidID: \(activityRecord["kidID"] ?? "nil")")
                            
                            do {
                                let savedRecord = try await privateDB.save(activityRecord)
                                print("COMPARTILHAMENTO: ✅ Atividade \(index + 1) configurada como filha: \(savedRecord.recordID.recordName)")
                                
                                // Verificar se ficou com parent após salvar
                                if let parent = savedRecord.parent {
                                    print("COMPARTILHAMENTO: ✅ Parent confirmado após salvar: \(parent.recordID.recordName)")
                                } else {
                                    print("COMPARTILHAMENTO: ⚠️ Parent não está definido após salvar!")
                                }
                                
                                successCount += 1
                            } catch {
                                let errorDescription = error.localizedDescription
                                if errorDescription.contains("already exists") {
                                    print("COMPARTILHAMENTO: ℹ️ Atividade \(index + 1) já existe, atualizando parent...")
                                    
                                    // Tentar buscar e atualizar o registro existente
                                    do {
                                        let existingRecord = try await privateDB.record(for: activityRecord.recordID)
                                        existingRecord.setParent(record)
                                        existingRecord["kidReference"] = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
                                        existingRecord["kidID"] = kidName
                                        
                                        let updatedRecord = try await privateDB.save(existingRecord)
                                        print("COMPARTILHAMENTO: ✅ Parent atualizado para atividade existente: \(updatedRecord.recordID.recordName)")
                                        successCount += 1
                                    } catch {
                                        print("COMPARTILHAMENTO: ❌ Erro ao atualizar parent da atividade existente: \(error)")
                                    }
                                } else {
                                    print("COMPARTILHAMENTO: ❌ Erro ao salvar atividade \(index + 1): \(errorDescription)")
                                }
                            }
                            
                            // Pequeno delay entre salvamentos para evitar conflitos
                            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundo
                        }
                    }
                    
                    print("COMPARTILHAMENTO: ✅ Hierarquia configurada: \(successCount)/\(activities.count) atividades como filhas")
                    
                    // Aguardar um pouco para o CloudKit processar a hierarquia
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                    
                    completion(.success(CloudSharingView(share: share, container: container)))
                    
                    // Marcar como enviado após criar o compartilhamento, necessário para a navegação
                    InvitationStatusManager.setStatus(.sent)
                    
                } else {
                    print("COMPARTILHAMENTO: Falha - compartilhamento existente não encontrado")
                    completion(.failure(.couldNotShareRecord))
                }
            } catch {
                print("COMPARTILHAMENTO: Erro ao usar compartilhamento existente: \(error.localizedDescription)")
                completion(.failure(.couldNotShareRecord))
            }
            
            return
        }
        
        // Criar novo compartilhamento
        print("COMPARTILHAMENTO: Criando novo compartilhamento para \(record["kidName"] ?? "Unknown")")
        
        // IMPORTANTE: Usar o construtor que recebe o rootRecord
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Compartilhando filho: \(record["kidName"] ?? "Unknown")"
        share.publicPermission = CKShare.ParticipantPermission.readWrite
        
        // Buscar todas as atividades relacionadas a este Kid
        let kidName = record.recordID.recordName
        print("COMPARTILHAMENTO: Compartilhando Kid com ID: \(kidName)")
        
        let activities = try await fetchRelatedActivities(kidName: kidName)
        print("COMPARTILHAMENTO: Encontradas \(activities.count) atividades para compartilhar")
        
        for (index, activity) in activities.enumerated() {
            print("COMPARTILHAMENTO: Atividade \(index): ID=\(activity.activityID), Data=\(activity.date)")
        }
        
        do {
            // NOVA ABORDAGEM: Configurar hierarquia pai-filho desde o início
            print("COMPARTILHAMENTO: Criando novo compartilhamento com hierarquia pai-filho...")
            
            // 1. Primeiro configurar as atividades como filhas ANTES de criar o compartilhamento
            var successCount = 0
            for (index, activity) in activities.enumerated() {
                if let activityRecord = activity.associatedRecord {
                    print("COMPARTILHAMENTO: Pré-configurando atividade \(index + 1)/\(activities.count) como filha...")
                    
                    // CONFIGURAR HIERARQUIA PAI-FILHO EXPLÍCITA
                    activityRecord.setParent(record)
                    
                    // Manter a kidReference também para busca
                    activityRecord["kidReference"] = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
                    activityRecord["kidID"] = kidName
                    
                    do {
                        let savedRecord = try await privateDB.save(activityRecord)
                        print("COMPARTILHAMENTO: ✅ Atividade \(index + 1) pré-configurada como filha: \(savedRecord.recordID.recordName)")
                        successCount += 1
                    } catch {
                        print("COMPARTILHAMENTO: ❌ Erro ao pré-configurar atividade \(index + 1): \(error.localizedDescription)")
                    }
                    
                    // Pequeno delay entre salvamentos
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundo
                }
            }
            
            print("COMPARTILHAMENTO: ✅ Pré-configuradas \(successCount)/\(activities.count) atividades como filhas")
            
            // 2. Agora criar o compartilhamento (que deve incluir as atividades automaticamente)
            let (initialResults, _) = try await privateDB.modifyRecords(saving: [record, share], deleting: [])
            print("COMPARTILHAMENTO: ✅ Compartilhamento criado com hierarquia: \(initialResults.count) registros base")
            
            // Aguardar um pouco para o CloudKit processar
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
            
            completion(.success(CloudSharingView(share: share, container: container)))
            
            // Marcar como enviado após criar o compartilhamento, necessário para a navegação
            InvitationStatusManager.setStatus(.sent)
            
        } catch {
            print("COMPARTILHAMENTO: Erro ao criar compartilhamento com hierarquia: \(error.localizedDescription)")
            completion(.failure(.couldNotShareRecord))
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
    
    func updateActivity(_ activity: ActivitiesRegister, isShared: Bool, completion: @escaping (Result<ActivitiesRegister, CloudError>) -> Void) {
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        client.modify(activity, dbType: dbType, completion: completion)
    }
    
    func deleteActivity(_ activity: ActivitiesRegister, isShared: Bool, completion: @escaping (Result<Bool, CloudError>) -> Void) {
        let dbType: CloudConfig = isShared ? .sharedDB : .privateDB
        client.delete(activity, dbType: dbType, completion: completion)
    }
    
    // Método auxiliar para buscar atividades relacionadas
    private func fetchRelatedActivities(kidName: String) async throws -> [ActivitiesRegister] {
        print("BUSCA-ATIVIDADES: Buscando atividades para o Kid ID: \(kidName)")
        let predicate = NSPredicate(format: "kidID == %@", kidName)
        
        return try await withCheckedThrowingContinuation { continuation in
            client.fetch(
                recordType: RecordType.activity.rawValue,
                dbType: .privateDB,
                inZone: CloudConfig.recordZone.zoneID,
                predicate: predicate
            ) { (result: Result<[ActivitiesRegister], CloudError>) in
                do {
                    let activities = try result.get()
                    print("BUSCA-ATIVIDADES: Encontradas \(activities.count) atividades")
                    continuation.resume(returning: activities)
                } catch {
                    print("BUSCA-ATIVIDADES: Erro ao buscar atividades: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchSharedActivities(forKid kidID: String, completion: @escaping (Result<[ActivitiesRegister], CloudError>) -> Void) {
        guard let rootRecordID = getRootRecordID() else {
            print("SHARED: Nenhum rootRecordID encontrado no UserDefaults")
            completion(.failure(.kidNotCreated))
            return
        }
        
        print("SHARED: Buscando atividades compartilhadas para kidID: \(kidID)")
        print("SHARED: Usando rootRecordID.zoneID: \(rootRecordID.zoneID.zoneName)")
        
        // Buscar usando o campo kidID
        let predicate = NSPredicate(format: "kidID == %@", kidID)
        
        client.fetch(
            recordType: RecordType.activity.rawValue,
            dbType: .sharedDB,
            inZone: rootRecordID.zoneID,
            predicate: predicate
        ) { (result: Result<[ActivitiesRegister], CloudError>) in
            switch result {
            case .success(let activities):
                print("SHARED: Sucesso! Encontradas \(activities.count) atividades com predicate kidID")
                let sortedActivities = activities.sorted {
                    $0.date < $1.date
                }
                completion(.success(sortedActivities))
            case .failure(let error):
                print("SHARED: Falha ao buscar por kidID: \(error)")
                
                // Se falhar com a busca por kidID, tentar buscar pela referência ao Kid
                print("SHARED: Tentando buscar por referência ao Kid")
                let parentPredicate = NSPredicate(format: "kidReference == %@", CKRecord.Reference(recordID: rootRecordID, action: .none))
                
                self.client.fetch(
                    recordType: RecordType.activity.rawValue,
                    dbType: .sharedDB,
                    inZone: rootRecordID.zoneID,
                    predicate: parentPredicate
                ) { (parentResult: Result<[ActivitiesRegister], CloudError>) in
                    switch parentResult {
                    case .success(let parentActivities):
                        print("SHARED: Sucesso! Encontradas \(parentActivities.count) atividades com predicate parentReference")
                        let sortedActivities = parentActivities.sorted {
                            $0.date < $1.date
                        }
                        completion(.success(sortedActivities))
                    case .failure(let parentError):
                        print("SHARED: Falha também ao buscar por referência: \(parentError)")
                        completion(.failure(parentError))
                    }
                }
            }
        }
    }
    
    
    // MARK: - Debug Operations
    
    func debugSharedDatabase() async {
        print("DEBUG: Iniciando verificação do banco compartilhado")
        
        // Use self.getRootRecordID() para acessar o método da extensão
        guard self.getRootRecordID() != nil else {
            print("DEBUG: Nenhum rootRecordID encontrado")
            return
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let sharedDB = container.sharedCloudDatabase
        
        do {
            // Buscar todas as zonas no banco compartilhado
            let zones = try await sharedDB.allRecordZones()
            print("DEBUG: Zonas no banco compartilhado: \(zones.map { $0.zoneID.zoneName })")
            
            // Buscar todos os registros em cada zona
            for zone in zones {
                print("DEBUG: Registros na zona \(zone.zoneID.zoneName):")
                
                // Buscar todos os tipos de registro
                for recordType in ["Kid", "ScheduledActivity"] {
                    let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                    
                    do {
                        let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                        print("DEBUG: - \(recordType): \(results.count) registros")
                        
                        for result in results {
                            switch result.1 {
                            case .success(let record):
                                print("DEBUG:   - ID: \(record.recordID.recordName)")
                                print("DEBUG:     Campos: \(record.allKeys().map { "\($0): \(String(describing: record[$0]))" }.joined(separator: ", "))")
                            case .failure(let error):
                                print("DEBUG:   - Erro: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("DEBUG: Erro ao buscar registros do tipo \(recordType): \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("DEBUG: Erro ao verificar banco compartilhado: \(error.localizedDescription)")
        }
    }
    
    func debugShareStatus(forKid kid: Kid) async {
        guard let record = kid.associatedRecord, let shareReference = record.share else {
            print("DEBUG: Kid não tem compartilhamento")
            return
        }
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let privateDB = container.privateCloudDatabase
        
        do {
            let share = try await privateDB.record(for: shareReference.recordID) as? CKShare
            print("DEBUG: Share encontrado: \(share?.recordID.recordName ?? "unknown")")
            print("DEBUG: Share permissions: \(share?.publicPermission.rawValue ?? -1)")
            print("DEBUG: Share participants: \(share?.participants.count ?? 0)")
            
            // Verificar atividades vinculadas ao compartilhamento
            let kidName = record.recordID.recordName
            // Buscar atividades relacionadas
            let predicate = NSPredicate(format: "kidID == %@", kidName)
            
            // Usamos uma Task aninhada aqui para evitar problemas de completion handler
            let activities = await withCheckedContinuation { continuation in
                self.client.fetch(
                    recordType: RecordType.activity.rawValue,
                    dbType: .privateDB,
                    inZone: CloudConfig.recordZone.zoneID,
                    predicate: predicate
                ) { (result: Result<[ActivitiesRegister], CloudError>) in
                    switch result {
                    case .success(let activities):
                        continuation.resume(returning: activities)
                    case .failure:
                        continuation.resume(returning: [])
                    }
                }
            }
            
            print("DEBUG: Encontradas \(activities.count) atividades relacionadas ao Kid")
            
            for (index, activity) in activities.enumerated() {
                if let activityRecord = activity.associatedRecord {
                    let isShared = activityRecord.share != nil
                    let hasKidRef = activityRecord["kidReference"] != nil
                    
                    print("DEBUG: Atividade \(index): ID=\(activity.activityID)")
                    print("  - isShared: \(isShared)")
                    print("  - hasKidRef: \(hasKidRef)")
                    print("  - Record ID: \(activityRecord.recordID.recordName)")
                }
            }
        } catch {
            print("DEBUG: Erro ao verificar status do compartilhamento: \(error)")
        }
    }
    
    func inspectSharedDatabase() async {
        print("INSPEÇÃO: Examinando conteúdo completo do banco compartilhado")
        
        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let sharedDB = container.sharedCloudDatabase
        
        do {
            let zones = try await sharedDB.allRecordZones()
            print("INSPEÇÃO: Zonas disponíveis: \(zones.map { $0.zoneID.zoneName })")
            
            if zones.isEmpty {
                print("INSPEÇÃO: Nenhuma zona encontrada no banco compartilhado!")
            }
            
            for zone in zones {
                print("\nINSPEÇÃO: Conteúdo da zona \(zone.zoneID.zoneName):")
                
                // Buscar todos os tipos de registro possíveis
                for recordType in ["Kid", "ScheduledActivity"] {
                    let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                    
                    do {
                        let (results, _) = try await sharedDB.records(matching: query, inZoneWith: zone.zoneID)
                        print("INSPEÇÃO: - \(recordType): \(results.count) registros")
                        
                        for (id, result) in results {
                            switch result {
                            case .success(let record):
                                print("INSPEÇÃO:   - ID: \(id.recordName)")
                                print("INSPEÇÃO:     Campos: \(record.allKeys().map { "\($0): \(String(describing: record[$0]))" }.joined(separator: ", "))")
                                
                                // Verificar compartilhamento
                                if let shareRef = record.share {
                                    print("INSPEÇÃO:     Tem share reference? Sim - \(shareRef.recordID.recordName)")
                                    
                                    // Tentar buscar o share em si
                                    do {
                                        if let share = try await sharedDB.record(for: shareRef.recordID) as? CKShare {
                                            print("INSPEÇÃO:     Share encontrado!")
                                            print("INSPEÇÃO:     Share permissões públicas: \(share.publicPermission.rawValue)")
                                            print("INSPEÇÃO:     Share participantes: \(share.participants.count)")
                                        }
                                    } catch {
                                        print("INSPEÇÃO:     Erro ao buscar share: \(error.localizedDescription)")
                                    }
                                } else {
                                    print("INSPEÇÃO:     Tem share? Não")
                                }
                                
                                // Verificar referências específicas
                                if recordType == "ScheduledActivity" {
                                    if let kidRef = record["kidReference"] as? CKRecord.Reference {
                                        print("INSPEÇÃO:     kidReference aponta para: \(kidRef.recordID.recordName)")
                                    } else {
                                        print("INSPEÇÃO:     Não tem kidReference!")
                                    }
                                    
                                    if let kidID = record["kidID"] as? String {
                                        print("INSPEÇÃO:     kidID: \(kidID)")
                                    } else {
                                        print("INSPEÇÃO:     Não tem kidID!")
                                    }
                                }
                            case .failure(let error):
                                print("INSPEÇÃO:   - Erro ao buscar \(id.recordName): \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("INSPEÇÃO: Erro ao buscar registros do tipo \(recordType): \(error.localizedDescription)")
                    }
                }
            }
            
            // Verificar o rootRecordID salvo
            if let rootID = self.getRootRecordID() {
                print("\nINSPEÇÃO: Root Record ID salvo: \(rootID.recordName)")
                print("INSPEÇÃO: Root Record Zone: \(rootID.zoneID.zoneName)")
                
                // Tentar buscar o registro raiz diretamente
                do {
                    let rootRecord = try await sharedDB.record(for: rootID)
                    print("INSPEÇÃO: Root Record encontrado!")
                    print("INSPEÇÃO: Root Record tipo: \(rootRecord.recordType)")
                    print("INSPEÇÃO: Root Record campos: \(rootRecord.allKeys().map { "\($0): \(String(describing: rootRecord[$0]))" }.joined(separator: ", "))")
                    
                    // Verificar se tem share
                    if let share = rootRecord.share {
                        print("INSPEÇÃO: Root Record tem compartilhamento reference: \(share.recordID.recordName)")
                    } else {
                        print("INSPEÇÃO: Root Record não tem compartilhamento!")
                    }
                } catch {
                    print("INSPEÇÃO: Erro ao buscar Root Record: \(error.localizedDescription)")
                }
            } else {
                print("\nINSPEÇÃO: Nenhum Root Record ID salvo!")
            }
        } catch {
            print("INSPEÇÃO: Erro ao listar zonas: \(error.localizedDescription)")
        }
    }
}

// MARK: - Utility Extensions

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
