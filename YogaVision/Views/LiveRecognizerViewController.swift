//
//  LiveRecognizerViewController.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/11/21.
//

import AVFoundation
import Resolver
import UIKit
import Vision

class LiveRecognizerViewController: CameraBufferViewController {

  /// LiveRecognizer dependency performs Vision and ML requests
  @Injected var livePoseRecognizer: LiveRecognizer
  /// View State Observable Object
  @Injected var mlInfo: MLInfo

  private var detectionOverlay: CALayer!
  // Communicate with the session and other session objects on this queue.
  private let semaphore = DispatchSemaphore(value: 0)

  override func setupAVCapture() {
    super.setupAVCapture()
    // setup Vision parts
    setupLayers()
    updateLayerGeometry()
    livePoseRecognizer.setupPoseVision { [self] (poseObservation) in
      guard let poseObservation = poseObservation else { return }
      DispatchQueue.main.async {
        let drawPoints = processObservation(poseObservation, normalizedFor: view.bounds)
        drawVisionRequestResults(drawPoints)
      }
    }
    // start the capture
    startCaptureSession()
  }

  func drawVisionRequestResults(_ points: [CGPoint]) {
    livePoseRecognizer.performPrediction { (arg0) in
      let (mountainPose, plankPose) = arg0
      DispatchQueue.main.async { [self] in
        mlInfo.mountainPose = mountainPose
        mlInfo.plank = plankPose
      }
    }

    DispatchQueue.main.async { [self] in
      CATransaction.begin()
      CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
      detectionOverlay.sublayers = nil // remove all the old recognized objects

      points.forEach { point in
        let shapeLayer = self.createBodyPoint(point)
        detectionOverlay.addSublayer(shapeLayer)
      }

      updateLayerGeometry()
      CATransaction.commit()
    }
  }

  override func captureOutput(_: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    livePoseRecognizer.analyzeCurrentBuffer(pixelBuffer: pixelBuffer) {
    }
  }


  func setupLayers() {
    detectionOverlay = CALayer() // container layer that has all the renderings of the observations
    detectionOverlay.name = "DetectionOverlay"
    detectionOverlay.bounds = view.bounds
    rootLayer.addSublayer(detectionOverlay)
  }

  func processObservation(_ observation: VNHumanBodyPoseObservation,
                          normalizedFor viewBounds: CGRect) -> [CGPoint]  {
    // Retrieve all points.
    guard let bodyPoints = try? observation.recognizedPoints(.all) else {
      return []
    }

    // JointKeys that need to be drawn on the screen
    let jointKeys: [VNHumanBodyPoseObservation.JointName] = [.leftAnkle, .leftElbow, .leftHip, .leftKnee, .leftShoulder, .leftWrist, .neck, .nose, .rightAnkle, .rightElbow, .rightHip, .rightKnee, .rightShoulder, .rightWrist]

    // Retrieve the CGPoints containing the normalized X and Y coordinates.
    let imagePoints: [CGPoint] = jointKeys.compactMap {
      guard let point = bodyPoints[$0], point.confidence > 0 else { return nil }

      // Translate the point from normalized-coordinates to image coordinates.
      return VNImagePointForNormalizedPoint(point.location, Int(view.bounds.size.width), Int(view.bounds.size.height))
    }
    // return the points to be drawn on screen.

    return imagePoints
  }
  
  func updateLayerGeometry() {
    let bounds = view.bounds
    var scale: CGFloat

    let xScale: CGFloat = bounds.size.width / bufferSize.height
    let yScale: CGFloat = bounds.size.height / bufferSize.width

    scale = fmax(xScale, yScale)
    if scale.isInfinite {
      scale = 1.0
    }
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

    // rotate the layer into screen orientation and scale and mirror
    detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
    // center the layer
    detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)

    CATransaction.commit()
  }

  private func createBodyPoint(_ point: CGPoint) -> CALayer {
    let shapeLayer = CALayer()
    shapeLayer.bounds = CGRect(x: point.x, y: point.y, width: 10, height: 10)
    shapeLayer.position = CGPoint(x: point.x, y: point.y)
    shapeLayer.name = "Found Object"
    shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.9])
    shapeLayer.cornerRadius = 7
    return shapeLayer
  }

}
