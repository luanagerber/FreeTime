//
//  CloudKitSharingView.swift
//  FreeTime
//
//  Created by Luana Gerber on 14/05/25.
//

import Foundation
import SwiftUI
import UIKit
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    let share: CKShare
    let container: CKContainer

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        print(share.url)
        let sharingController = UICloudSharingController(share: share, container: container)
        
        
        sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        sharingController.delegate = context.coordinator
        sharingController.modalPresentationStyle = .fullScreen
        return sharingController
    }

    func makeCoordinator() -> CloudSharingView.Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            debugPrint("Error saving share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            NSLocalizedString("Compartilhando atividade", comment: "")
        }
        
    }
}

