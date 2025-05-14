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

//    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
//        guard cloudKitShareMetadata.containerIdentifier == CloudConfig.containerIndentifier else {
//            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
//            return
//        }
//
//        let container = CKContainer(identifier: CloudConfig.containerIndentifier)
//        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
//
//        debugPrint("Beggining to accept CloudKit Share with metadata: \(cloudKitShareMetadata)")
//        operation.perShareResultBlock = { metadata, result in
//            switch result {
//            case .success:
//                if let rootRecordID = metadata.hierarchicalRootRecordID {
//                    CloudService.shared.saveRootRecordID(rootRecordID)
//                    NotificationCenter.default.post(name: .didAcceptCloudKitShare, object: nil)
//                    debugPrint("Accepted share with root record ID: \(rootRecordID)")
//                } else {
//                    debugPrint("Accepted share with no root record ID")
//                }
//            case .failure(let error):
//                debugPrint("Error accepting share with root record ID: \(metadata.hierarchicalRootRecordID.debugDescription), \(error)")
//            }
//        }
//        
//        operation.acceptSharesResultBlock = { result in
//            if case .failure(let error) = result {
//                debugPrint("Error accepting CloudKit Share: \(error)")
//            }
//        }
//        
//        operation.qualityOfService = .utility
//        container.add(operation)
//    }
}
