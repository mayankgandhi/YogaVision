//
//  PoseRecognizer.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/9/21.
//

import Foundation
import AVFoundation
import Vision

final class PoseRecognizer {

  let predictionWindow = 90
  let model = try? YogaVision(configuration: MLModelConfiguration())

  func recognizeYogaPose(from url: URL, completion: @escaping (Bool)->Void ) {
    grabPoses(from: url) { [self] (poses) in
      let poses = poses.prefix(predictionWindow).map { x in x }
      if let prediction = self.makePrediction(posesWindow: poses) {
        prediction.featureNames.forEach { print("\($0) - \(prediction.featureValue(for: $0))") }
      }
    }
  }

  func grabPoses(from assetURL: URL, completion: @escaping ([VNHumanBodyPoseObservation])->Void) {
    var allPoses = [VNHumanBodyPoseObservation]()
    let asset = AVAsset(url: assetURL)
    let visionRequest = VNDetectHumanBodyPoseRequest { (vnRequest, error) in
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
      try videoProcessor.analyze(CMTimeRange(start: .zero, duration: asset.duration))
      completion(allPoses)
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  /// Make a model prediction on a window.
  func makePrediction(posesWindow: [VNHumanBodyPoseObservation]) -> MLFeatureProvider? {
    // Prepare model input: convert each pose to a multi-array, and concatenate multi-arrays.
    let poseMultiArrays: [MLMultiArray] = posesWindow.map({ try! $0.keypointsMultiArray() })
    let modelInput = MLMultiArray(concatenating: poseMultiArrays, axis: 0, dataType: .float)
    var prediction: MLFeatureProvider?
    // Perform prediction
    do {
      prediction = try model?.prediction(input: YogaVisionInput(poses: modelInput))
    } catch {
      fatalError(error.localizedDescription)
    }
    return prediction
  }

}
/Users/mayankgandhi/XcodeProjects/YogaVision/Pods
