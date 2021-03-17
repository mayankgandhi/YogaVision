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

  // Instance Properties
  private var requests = [VNDetectHumanBodyPoseRequest]()
  private let sequenceHandler = VNSequenceRequestHandler()
  private var bodyPoseObservations = [VNHumanBodyPoseObservation]()

  // Setup Vision Request to perform on CVPixelBuffer
  func setupPoseVision(completion: @escaping (VNHumanBodyPoseObservation?)->Void ) {
    let visionRequest = VNDetectHumanBodyPoseRequest { [self] vnRequest, error in
      if let error = error {
        fatalError(error.localizedDescription)
      }
      if let poseObservations = vnRequest.results {
        completion(transformBodyPoseObservation(from: poseObservations))
      }
    }
    requests = [visionRequest]
  } 

  func analyzeCurrentBuffer(pixelBuffer: CVPixelBuffer) {
    /// Get the CGImageOrientation reference to the UIDeviceOrientation
    /// used to perform Vision Request
    let exifOrientation = exifOrientationFromDeviceOrientation()
    do {
      try sequenceHandler.perform(requests, on: pixelBuffer, orientation: exifOrientation)
    } catch {
      print(error)
    }
  }

  func transformBodyPoseObservation(from results: [Any]) -> VNHumanBodyPoseObservation? {
    for observation in results where observation is VNHumanBodyPoseObservation {
      guard let bodyPoseObservation = observation as? VNHumanBodyPoseObservation else {
        continue
      }
      // Get the most prominent VNHumanBodyPoseObservation
      bodyPoseObservations.append(bodyPoseObservation)
      return bodyPoseObservation
    }
    return nil
  }

  func performPrediction(completion: ((Float, Float)) -> Void) {
    /// Check if we have enough VNBodyPoseObservation for the MLModelInput
    guard bodyPoseObservations.count == predictionWindow else { return }
    let predictionWindowPoses: [VNHumanBodyPoseObservation] = bodyPoseObservations.prefix(predictionWindow).map { $0 }

    guard let prediction = makePrediction(posesWindow: predictionWindowPoses),
          let probabilities = prediction.featureValue(for: "labelProbabilities") else { return }

    /// Calculate Probability Percentages that need to be drawn on screen
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
