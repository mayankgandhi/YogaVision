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
    @Injected var livePoseRecognizer: LiveRecognizer
    @Injected var mlInfo: MLInfo

    private var detectionOverlay: CALayer!

    private var bodyPoseObservations = [VNHumanBodyPoseObservation]()

    override func setupAVCapture() {
        super.setupAVCapture()
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        livePoseRecognizer.setupPoseVision { poseObservations in
            self.drawVisionRequestResults(poseObservations)
        }
        // start the capture
        startCaptureSession()
    }

    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNHumanBodyPoseObservation {
            guard let bodyPoseObservation = observation as? VNHumanBodyPoseObservation else {
                continue
            }
            bodyPoseObservations.append(bodyPoseObservation)
            livePoseRecognizer.performPrediction(with: bodyPoseObservations) { predictionProbabilities in
                bodyPoseObservations.removeFirst(livePoseRecognizer.predictionWindow)
                DispatchQueue.main.async { [self] in
                    mlInfo.mountainPose = predictionProbabilities.0
                    mlInfo.plank = predictionProbabilities.1
                }
            }

            // Select only the label with the highest confidence.
            let bodyPoints = livePoseRecognizer.processObservation(bodyPoseObservation, normalizedFor: view.bounds)
            bodyPoints.forEach { point in
                let shapeLayer = self.createBodyPoint(point)
                detectionOverlay.addSublayer(shapeLayer)
            }
        }
        updateLayerGeometry()
        CATransaction.commit()
    }

    override func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        livePoseRecognizer.analyzeCurrentBuffer(pixelBuffer: pixelBuffer)
    }

    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = view.bounds
        rootLayer.addSublayer(detectionOverlay)
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

    func createBodyPoint(_ point: CGPoint) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = CGRect(x: point.x, y: point.y, width: 10, height: 10)
        shapeLayer.position = CGPoint(x: point.x, y: point.y)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.9])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}
