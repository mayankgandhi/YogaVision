//
//  LiveRecognizerViewController.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/11/21.
//

import UIKit
import Vision
import AVFoundation

class LiveRecognizerViewController: CameraBufferViewController {

  private var detectionOverlay: CALayer! = nil

  // Vision parts
  private var requests = [VNDetectHumanBodyPoseRequest]()

  private var imageRequest = [VNRequest]()

  override func setupAVCapture() {
    super.setupAVCapture()
    // setup Vision parts
    setupLayers()
    updateLayerGeometry()
    setupPoseVision()
    setupImageVision()
    // start the capture
    startCaptureSession()
  }

  func setupPoseVision() {
    let visionRequest = VNDetectHumanBodyPoseRequest { [self] (vnRequest, error) in
      print("Pose Request Executed")
      if let error = error {
        fatalError(error.localizedDescription)
      }
      if let poseObservations = vnRequest.results {
        drawVisionRequestResults(poseObservations)
      }
    }
    self.requests = [visionRequest]
  }

  func setupImageVision() {
    do {
      let visionModel = try VNCoreMLModel(for: YogaImageClassifier().model)
      let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
        print("image Request Executed")
        DispatchQueue.main.async(execute: {
          // perform all the UI updates on the main queue
          if let results = request.results {
            print(results)
            self.drawImageRequestResults(results)
          }
        })
      })
      self.imageRequest = [objectRecognition]
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func drawVisionRequestResults(_ results: [Any]) {
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    detectionOverlay.sublayers = nil // remove all the old recognized objects
    for observation in results where observation is VNHumanBodyPoseObservation {
      guard let objectObservation = observation as? VNHumanBodyPoseObservation else {
        continue
      }
      // Select only the label with the highest confidence.
      let bodyPoints = processObservation(objectObservation)
      print(bodyPoints)
      bodyPoints.forEach { (point) in
        let shapeLayer = self.createBodyPoint(point)
        detectionOverlay.addSublayer(shapeLayer)
      }
    }
    self.updateLayerGeometry()
    CATransaction.commit()
  }

  func drawImageRequestResults(_ results: [Any]) {
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    detectionOverlay.sublayers = nil // remove all the old recognized objects
    for observation in results where observation is VNRecognizedObjectObservation {
      guard let objectObservation = observation as? VNRecognizedObjectObservation else {
        continue
      }
      // Select only the label with the highest confidence.
      let topLabelObservation = objectObservation.labels[0]
      let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))

      let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)

      let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                      identifier: topLabelObservation.identifier,
                                                      confidence: topLabelObservation.confidence)
      shapeLayer.addSublayer(textLayer)
      detectionOverlay.addSublayer(shapeLayer)
    }
    self.updateLayerGeometry()
    CATransaction.commit()
  }

  func processObservation(_ observation: VNHumanBodyPoseObservation) -> [CGPoint] {

    // Retrieve all torso points.
    guard let bodyPoints =
            try? observation.recognizedPoints(.all) else {
      return []
    }

    // Torso point keys in a clockwise ordering.
    let jointKeys: [VNHumanBodyPoseObservation.JointName] = [ .leftAnkle, .leftEar, .leftElbow, .leftEye, .leftHip, .leftKnee, .leftShoulder, .leftWrist, .neck, .nose, .rightAnkle, .rightEar, .rightElbow, .rightEye, .rightHip, .rightKnee, .rightShoulder, .rightWrist]

    // Retrieve the CGPoints containing the normalized X and Y coordinates.
    let imagePoints: [CGPoint] = jointKeys.compactMap {
      guard let point = bodyPoints[$0], point.confidence > 0 else { return nil }

      // Translate the point from normalized-coordinates to image coordinates.
      return VNImagePointForNormalizedPoint(point.location,
                                            Int(previewLayer.bounds.width),
                                            Int(previewLayer.bounds.height))
    }
    // Draw the points onscreen.
    return imagePoints
  }

  override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    let exifOrientation = exifOrientationFromDeviceOrientation()
    let sequenceHandler = VNSequenceRequestHandler()
    do {
      try sequenceHandler.perform(self.requests, on: pixelBuffer, orientation: exifOrientation)
//      try sequenceHandler.perform(self.imageRequest, on: pixelBuffer, orientation: exifOrientation)
    } catch {
      print(error)
    }
  }

  func setupLayers() {
    detectionOverlay = CALayer() // container layer that has all the renderings of the observations
    detectionOverlay.name = "DetectionOverlay"
    detectionOverlay.bounds = rootLayer.bounds
    rootLayer.addSublayer(detectionOverlay)
  }

  func updateLayerGeometry() {
    let bounds = rootLayer.bounds
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

  func createBodyPoint(_ point: CGPoint) -> CALayer {
    let shapeLayer = CALayer()
    shapeLayer.bounds = CGRect(x: point.x, y: point.y, width: 10, height: 10)
    shapeLayer.position = CGPoint(x: point.x, y: point.y)
    shapeLayer.name = "Found Object"
    shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.9])
    shapeLayer.cornerRadius = 7
    return shapeLayer
  }

  func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.name = "Object Label"
    let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
    let largeFont = UIFont(name: "Helvetica", size: 24.0)!
    formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
    textLayer.string = formattedString
    textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
    textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    textLayer.shadowOpacity = 0.7
    textLayer.shadowOffset = CGSize(width: 2, height: 2)
    textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
    textLayer.contentsScale = 2.0 // retina rendering
    // rotate the layer into screen orientation and scale and mirror
    textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    return textLayer
  }

  func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
    let shapeLayer = CALayer()
    shapeLayer.bounds = bounds
    shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    shapeLayer.name = "Found Object"
    shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
    shapeLayer.cornerRadius = 7
    return shapeLayer
  }

}
