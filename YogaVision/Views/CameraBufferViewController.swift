//
//  CameraBufferViewController.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/11/21.
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

class CameraBufferViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  var bufferSize: CGSize = .zero
  var rootLayer: CALayer!

  var previewView: UIView!
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "session queue")
  var previewLayer: AVCaptureVideoPreviewLayer!
  private let videoDataOutput = AVCaptureVideoDataOutput()

  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

  func captureOutput(_: AVCaptureOutput, didOutput _: CMSampleBuffer, from _: AVCaptureConnection) {
    // to be implemented in the subclass
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    previewView = UIView(frame: view.bounds)
    setupAVCapture()
    view.addSubview(previewView)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startCaptureSession()
  }

  func setupAVCapture() {
    var deviceInput: AVCaptureDeviceInput!

    // Select a video device, make an input
    let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
    do {
      deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
    } catch {
      print("Could not create video device input: \(error)")
      return
    }

    sessionQueue.async { [self] in
      session.beginConfiguration()
      // Model image size is smaller.
      session.sessionPreset = .hd1280x720

      // Add a video input
      guard session.canAddInput(deviceInput) else {
        print("Could not add video device input to the session")
        session.commitConfiguration()
        return
      }
      session.addInput(deviceInput)
      if session.canAddOutput(videoDataOutput) {
        session.addOutput(videoDataOutput)
        // Add a video data output
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
      } else {
        print("Could not add video data output to the session")
        session.commitConfiguration()
        return
      }
      let captureConnection = videoDataOutput.connection(with: .video)
      // Always process the frames
      captureConnection?.isEnabled = true
      do {
        try videoDevice!.lockForConfiguration()
        let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
        bufferSize.width = CGFloat(dimensions.width)
        bufferSize.height = CGFloat(dimensions.height)
        videoDevice!.unlockForConfiguration()
      } catch {
        print(error)
      }
      session.commitConfiguration()
    }
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    rootLayer = previewView.layer
    previewLayer.frame = rootLayer.bounds
    rootLayer.addSublayer(previewLayer)
  }

  func startCaptureSession() {
    sessionQueue.async {
      self.session.startRunning()
    }
  }

  // Clean up capture setup
  func teardownAVCapture() {
    previewLayer.removeFromSuperlayer()
    previewLayer = nil
  }

  func captureOutput(_: AVCaptureOutput, didDrop _: CMSampleBuffer, from _: AVCaptureConnection) {
    // print("frame dropped")
  }
}
