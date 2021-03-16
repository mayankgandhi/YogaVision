//
//  VideoRecognizer.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/12/21.
//

import AVFoundation
import Foundation
import Vision

final class VideoRecognizer: PoseRecognizer {

    func recognizeYogaPose(from url: URL) {
        grabPoses(from: url) { [self] poses in
            let poses = poses.prefix(predictionWindow).map { x in x }
            if let prediction = self.makePrediction(posesWindow: poses) {
                prediction.featureNames.forEach { print("\($0) - \(prediction.featureValue(for: $0))") }
            }
        }
    }

    func grabPoses(from assetURL: URL, completion: @escaping ([VNHumanBodyPoseObservation]) -> Void) {
        var allPoses = [VNHumanBodyPoseObservation]()
        let asset = AVAsset(url: assetURL)
        let visionRequest = VNDetectHumanBodyPoseRequest { vnRequest, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            if let poseObservations = vnRequest.results as? [VNHumanBodyPoseObservation] {
                allPoses.append(contentsOf: poseObservations)
            }
        }

        do {
            let videoProcessor = VNVideoProcessor(url: assetURL)
            try videoProcessor.addRequest(visionRequest, processingOptions: VNVideoProcessor.RequestProcessingOptions())
            try videoProcessor.analyze(CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: .min)))
            completion(allPoses)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}
