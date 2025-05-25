//
//  ActivityViewUI.swift
//  FreeTime
//
//  Created by Luana Gerber on 24/05/25.
//

import SwiftUI
import UIKit

struct ActivityViewUI: UIViewControllerRepresentable {
    let activityItems: [Any]
    let completion: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            completion(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
