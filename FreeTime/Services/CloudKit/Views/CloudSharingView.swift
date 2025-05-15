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
        // Maneira mais segura de imprimir a URL opcional
        if let url = share.url {
            print("Share URL: \(url)")
        } else {
            print("Share URL is not available yet")
        }
        
        let sharingController = UICloudSharingController(share: share, container: container)
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

