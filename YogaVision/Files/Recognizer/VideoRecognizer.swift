//
//  VideoRecognizer.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/12/21.
//

import AVFoundation
import Foundation
import Resolver
import Vision

final class VideoRecognizer: PoseRecognizer {
    @Injected var mlInfo: MLInfo

    func recognizeYogaPose(from url: URL) {
        mlInfo.preload()
        grabPoses(from: url) { [self] poses in
            let poses = poses.prefix(predictionWindow).map { x in x }
            DispatchQueue.main.async { self.mlInfo.progress = 60 }
            guard let prediction = makePrediction(posesWindow: poses),
                  let probabilities = prediction.featureValue(for: "labelProbabilities") else { return }
            /// Calculate Probability Percentages that need to be drawn on screen
            DispatchQueue.main.async {
                self.mlInfo.progress = 100
                mlInfo.mountainPose = probabilities.dictionaryValue["MountainPose"]!.floatValue * 100
                mlInfo.plank = probabilities.dictionaryValue["Plank"]!.floatValue * 100
                mlInfo.loading = false
                mlInfo.show = true
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
                if allPoses.count == self.predictionWindow {
                    completion(allPoses)
                }
            }
        }
        do {
            let videoProcessor = VNVideoProcessor(url: assetURL)
            try videoProcessor.addRequest(visionRequest, processingOptions: VNVideoProcessor.RequestProcessingOptions())
            try videoProcessor.analyze(CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: .min)))

        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
