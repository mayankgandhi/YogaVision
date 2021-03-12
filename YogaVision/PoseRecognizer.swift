//
//  PoseRecognizer.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/9/21.
//

import Foundation
import AVFoundation
import Vision

class PoseRecognizer {

  let predictionWindow = 30
  let model = try? YogaVision(configuration: MLModelConfiguration())

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


