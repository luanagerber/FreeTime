//
//  SceneDelegate.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import UIKit
import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        guard cloudKitShareMetadata.containerIdentifier == CloudConfig.containerIdentifier else {
            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }

        let container = CKContainer(identifier: CloudConfig.containerIdentifier)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])

        debugPrint("Beggining to accept CloudKit Share with metadata: \(cloudKitShareMetadata)")
        operation.perShareResultBlock = { metadata, result in
            switch result {
            case .success:
                if let rootRecordID = metadata.hierarchicalRootRecordID {
                    CloudService.shared.saveRootRecordID(rootRecordID)
                    
                    // Busca o Kid para obter o nome
                    CloudService.shared.fetchKid(withRecordID: rootRecordID) { kidResult in
                        DispatchQueue.main.async {
                            switch kidResult {
                            case .success(let kid):
                                // Define o usuário como criança com todas as informações
                                UserManager.shared.setAsChild(withKid: kid)
                                
                            case .failure(let error):
                                print("Erro ao buscar informações da criança: \(error)")
                                // Define apenas com o ID se não conseguir buscar o nome
                                UserManager.shared.setAsChild(
                                    withKidID: rootRecordID,
                                    name: "Criança"
                                )
                            }
                            
                            NotificationCenter.default.post(name: .didAcceptCloudKitShare, object: nil)
                            InvitationStatusManager.setStatus(.accepted)
                        }
                    }
                    
                    debugPrint("Accepted share with root record ID: \(rootRecordID)")
                } else {
                    debugPrint("Accepted share with no root record ID")
                }
            case .failure(let error):
                InvitationStatusManager.setStatus(.pending)
                debugPrint("Error accepting share: \(error)")
            }
        }
        
        operation.acceptSharesResultBlock = { result in
            if case .failure(let error) = result {
                debugPrint("Error accepting CloudKit Share: \(error)")
            }
        }
        
        operation.qualityOfService = .utility
        container.add(operation)
    }
}
