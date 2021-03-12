//
//  LiveRecognizerViewController+Representable.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/11/21.
//

import Foundation
import SwiftUI

extension LiveRecognizerViewController {
    struct LiveRecognizerViewRepresentable: UIViewControllerRepresentable {
        typealias UIViewControllerType = LiveRecognizerViewController

        func makeUIViewController(context _: Context) -> LiveRecognizerViewController {
            LiveRecognizerViewController()
        }

        func updateUIViewController(_: LiveRecognizerViewController, context _: Context) {}
    }
}
