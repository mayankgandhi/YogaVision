//
//  LiveRecognizer.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/12/21.
//

import Foundation
import UIKit
import Vision

final class LiveRecognizer: PoseRecognizer {
    private var requests = [VNDetectHumanBodyPoseRequest]()

    func setupPoseVision(completion: @escaping ([Any]) -> Void) {
        let visionRequest = VNDetectHumanBodyPoseRequest { [self] vnRequest, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            if let poseObservations = vnRequest.results {
                completion(poseObservations)
            }
        }
        requests = [visionRequest]
    }

    func processObservation(_ observation: VNHumanBodyPoseObservation, normalizedFor viewBounds: CGRect) -> [CGPoint] {
        // Retrieve all points.
        guard let bodyPoints =
            try? observation.recognizedPoints(.all)
        else {
            return []
        }

        // JointKeys that need to be drawn on the screen
        let jointKeys: [VNHumanBodyPoseObservation.JointName] = [.leftAnkle, .leftElbow, .leftHip, .leftKnee, .leftShoulder, .leftWrist, .neck, .nose, .rightAnkle, .rightElbow, .rightHip, .rightKnee, .rightShoulder, .rightWrist]

        // Retrieve the CGPoints containing the normalized X and Y coordinates.
        let imagePoints: [CGPoint] = jointKeys.compactMap {
            guard let point = bodyPoints[$0], point.confidence > 0 else { return nil }

            // Translate the point from normalized-coordinates to image coordinates.
            return VNImagePointForNormalizedPoint(point.location,
                                                  Int(viewBounds.width),
                                                  Int(viewBounds.height))
        }
        // Draw the points onscreen.
        return imagePoints
    }

    func analyzeCurrentBuffer(pixelBuffer: CVPixelBuffer) {
        let exifOrientation = exifOrientationFromDeviceOrientation()
        let sequenceHandler = VNSequenceRequestHandler()
        do {
            try sequenceHandler.perform(requests, on: pixelBuffer, orientation: exifOrientation)
        } catch {
            print(error)
        }
    }

    func performPrediction(with bodyPoseObservations: [VNHumanBodyPoseObservation],
                           completion: ((Float, Float)) -> Void)
    {
        guard bodyPoseObservations.count == predictionWindow else { return }
        let predictionWindowPoses: [VNHumanBodyPoseObservation] = bodyPoseObservations.prefix(predictionWindow).map { $0 }

        guard let prediction = makePrediction(posesWindow: predictionWindowPoses),
              let probabilities = prediction.featureValue(for: "labelProbabilities") else { return }

        let mountainPoseProbability = probabilities.dictionaryValue["MountainPose"]!.floatValue * 100
        let plankPoseProbability = probabilities.dictionaryValue["Plank"]!.floatValue * 100
        completion((mountainPoseProbability, plankPoseProbability))
    }

    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation

        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown: // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft: // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight: // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait: // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
