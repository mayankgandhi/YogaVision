//
//  VideoPicker.swift
//  DanceVision
//
//  Created by Mayank Gandhi on 11/4/20.
//

import AVFoundation
import Foundation
import Resolver
import SwiftUI

struct VideoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var showVideoPicker: Bool
    @Binding var videoURL: URL

    var allowsEditing = true
    typealias UIViewControllerType = UIImagePickerController

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let myPickerController = UIImagePickerController()
        myPickerController.delegate = context.coordinator
        myPickerController.sourceType = .savedPhotosAlbum
        myPickerController.allowsEditing = allowsEditing
        myPickerController.mediaTypes = ["public.movie"]
        myPickerController.videoQuality = .typeHigh
        myPickerController.videoMaximumDuration = 15
        myPickerController.videoExportPreset = AVAssetExportPreset1280x720

        return myPickerController
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {
        //
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Injected var videoRecognizer: VideoRecognizer
        let parent: VideoPicker
        let fileService = FileService()

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = fileService.createTemporaryURLforVideoFile(url: url as NSURL)
                DispatchQueue.global().async { [self] in
                    videoRecognizer.recognizeYogaPose(from: parent.videoURL)
                }
            }
            DispatchQueue.main.async {
                self.parent.showVideoPicker = false
            }
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.showVideoPicker = false
        }
    }
}
