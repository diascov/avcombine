//
//  AVCombineCaptureService.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 25.02.2021.
//

import UIKit
import AVFoundation

public protocol AVCombineCaptureServiceDelegate: class {
  func didFinishCapture(image: UIImage)
  func didFinishCapture(asset: AVURLAsset)
  func didStartVideoCapture()
}

public enum AVCombineCaptureSource {
  case photo
  case video
  case undefined
}

public final class AVCombineCaptureService: NSObject, AVCombineFileManager {

  weak var delegate: AVCombineCaptureServiceDelegate?
  private var superLayer: CALayer
  private var maxRecordedDuration: Double?

  private var captureSession: AVCaptureSession?
  private var videoWriter: AVAssetWriter?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var videoWriterInput: AVAssetWriterInput?
  private var audioWriterInput: AVAssetWriterInput?
  private var photoOutput: AVCapturePhotoOutput?
  private var videoOutput: AVCaptureVideoDataOutput?
  private var audioOutput: AVCaptureAudioDataOutput?

  private var isRecording = false
  private var sessionSourceTime: CMTime?
  private var sessionCurrentTime: CMTime?
  private var uniqueUrl: URL?
  private var position: AVCaptureDevice.Position?
  private var flashMode: AVCaptureDevice.FlashMode = .off
  private var outputQueue = DispatchQueue(label: "output.queue")
  private var metadataQueue = DispatchQueue(label: "metadata.queue")

  public init(superLayer: CALayer,
              maxRecordedDuration: Double?,
              delegate: AVCombineCaptureServiceDelegate?) {
    self.superLayer = superLayer
    self.maxRecordedDuration = maxRecordedDuration
    self.delegate = delegate
    super.init()
  }

  public func startCapture(source: AVCombineCaptureSource) {
    if isRecording { return }
    switch source {
    case .photo:
      let photoSettings = AVCapturePhotoSettings()
      photoSettings.isAutoStillImageStabilizationEnabled = true
      photoSettings.flashMode = flashMode
      photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    case .video:
      isRecording = true
      videoWriter?.startWriting()
      delegate?.didStartVideoCapture()
    case .undefined:
      break
    }
  }

  public func stopCapture() {
    if !isRecording { return }
    isRecording = false
    sessionSourceTime = nil
    captureSession!.stopRunning()
    videoWriterInput?.markAsFinished()
    videoWriter?.finishWriting { [weak self] in
      guard let uniqueUrl = self?.uniqueUrl else { return }
      let asset = AVURLAsset(url: uniqueUrl)
      DispatchQueue.main.async {
        self?.setupCaptureSession(position: self?.position ?? .unspecified)
        self?.delegate?.didFinishCapture(asset: asset)
      }
    }
  }

  public func setupCaptureSession(position: AVCaptureDevice.Position) {
    self.position = position
    captureSession = AVCaptureSession()
    captureSession!.beginConfiguration()
    setupCaptureInputs()
    setupCaptureOutputs()
    updateMirroring()
    videoOutput!.setSampleBufferDelegate(self, queue: outputQueue)
    audioOutput!.setSampleBufferDelegate(self, queue: outputQueue)
    captureSession!.commitConfiguration()
    captureSession!.startRunning()
    setupWritter()
    setupLayer()
  }

  private func setupLayer() {
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
    previewLayer!.videoGravity = .resizeAspectFill
    previewLayer!.frame = superLayer.bounds
    superLayer.sublayers?
      .filter { $0 is AVCaptureVideoPreviewLayer }
      .forEach { $0.removeFromSuperlayer() }
    superLayer.insertSublayer(previewLayer!, at: 0)
  }

  public func changeCamera(position: AVCaptureDevice.Position) {
    self.position = position
    captureSession!.beginConfiguration()
    captureSession!.inputs.forEach {
      captureSession!.removeInput($0)
    }
    setupCaptureInputs()
    captureSession!.commitConfiguration()
    updateMirroring()
  }

  public func changeFlash(mode: AVCaptureDevice.FlashMode) {
    flashMode = mode
  }

  private func updateMirroring() {
    if let connection = videoOutput?.connection(with: .video) {
      connection.videoOrientation = .portrait
      connection.isVideoMirrored = connection.isVideoMirroringSupported && position == .front ? true : false
    }
    if let connection = photoOutput?.connection(with: .video) {
      connection.videoOrientation = .portrait
      connection.isVideoMirrored = connection.isVideoMirroringSupported && position == .front ? true : false
    }
  }

  private func setupCaptureOutputs() {
    captureSession?.outputs.forEach {
      captureSession!.removeOutput($0)
    }
    photoOutput = AVCapturePhotoOutput()
    if captureSession!.canAddOutput(photoOutput!) {
      captureSession!.addOutput(photoOutput!)
    }
    videoOutput = AVCaptureVideoDataOutput()
    if captureSession!.canAddOutput(videoOutput!) {
      captureSession!.addOutput(videoOutput!)
    }
    audioOutput = AVCaptureAudioDataOutput()
    if captureSession!.canAddOutput(audioOutput!) {
      captureSession!.addOutput(audioOutput!)
    }
    let metadataOutput = AVCaptureMetadataOutput()
    metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
    if captureSession!.canAddOutput(metadataOutput) {
      captureSession!.addOutput(metadataOutput)
    }
    metadataOutput.metadataObjectTypes = [.face]
  }

  private func setupCaptureInputs() {
    guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: position ?? .unspecified),
          let audioCaptureDevice = AVCaptureDevice.default(for: .audio) else { return }
    let videoInput: AVCaptureDeviceInput
    let audioInput: AVCaptureDeviceInput
    do {
      try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
      try audioInput = AVCaptureDeviceInput(device: audioCaptureDevice)
    } catch {
      return
    }
    captureSession!.inputs.forEach {
      captureSession!.removeInput($0)
    }
    if captureSession!.canAddInput(videoInput) && captureSession!.canAddInput(audioInput) {
      captureSession!.addInput(videoInput)
      captureSession!.addInput(audioInput)
    }
  }

  private func setupWritter() {
    uniqueUrl = uniqueUrl(for: .video)
    guard let uniqueUrl = uniqueUrl else { return }
    do {
      videoWriter = try AVAssetWriter(outputURL: uniqueUrl, fileType: .mov)
    } catch {
      return
    }
    videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: constants.videoInputSettings)
    guard let videoWriter = videoWriter,
          let videoWriterInput = videoWriterInput else { return }
    videoWriterInput.expectsMediaDataInRealTime = true
    if videoWriter.canAdd(videoWriterInput) {
      videoWriter.add(videoWriterInput)
    }
    audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
    guard let audioWriterInput = audioWriterInput else { return }
    audioWriterInput.expectsMediaDataInRealTime = true
    if videoWriter.canAdd(audioWriterInput) {
      videoWriter.add(audioWriterInput)
    }
  }

  private var isWritable: Bool {
    isRecording && videoWriter != nil && videoWriter?.status == .writing
  }

  private var isAcceptedDuration: Bool {
    guard let maxRecordedDuration = maxRecordedDuration else { return true }
    guard let sessionSourceTime = sessionSourceTime,
          let sessionCurrentTime = sessionCurrentTime else { return false }
    let startTime = Double(sessionSourceTime.value) / Double(sessionSourceTime.timescale)
    let currentTime = Double(sessionCurrentTime.value) / Double(sessionCurrentTime.timescale)
    return currentTime - startTime < maxRecordedDuration
  }
}

extension AVCombineCaptureService: AVCapturePhotoCaptureDelegate {

  public func photoOutput(_ output: AVCapturePhotoOutput,
                          didFinishProcessingPhoto photo: AVCapturePhoto,
                          error: Error?) {
    guard let data = photo.fileDataRepresentation() else { return }
    guard let image = UIImage(data: data, scale: 1.0) else { return }
    delegate?.didFinishCapture(image: image)
  }
}

extension AVCombineCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate,
                                   AVCaptureAudioDataOutputSampleBufferDelegate {

  public func captureOutput(_ output: AVCaptureOutput,
                            didOutput sampleBuffer: CMSampleBuffer,
                            from connection: AVCaptureConnection) {
    if isWritable, sessionSourceTime == nil {
      sessionSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      videoWriter?.startSession(atSourceTime: sessionSourceTime!)
    }
    if !isWritable {
      sessionCurrentTime = CMTime(seconds: 0, preferredTimescale: 1)
    } else {
      sessionCurrentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      if output == videoOutput, videoWriterInput?.isReadyForMoreMediaData == true {
        videoWriterInput?.append(sampleBuffer)
      }
      if output == audioOutput, audioWriterInput?.isReadyForMoreMediaData == true {
        audioWriterInput?.append(sampleBuffer)
      }
      if !isAcceptedDuration {
        stopCapture()
      }
    }
  }
}

extension AVCombineCaptureService: AVCaptureMetadataOutputObjectsDelegate {

  public func metadataOutput(_ output: AVCaptureMetadataOutput,
                             didOutput metadataObjects: [AVMetadataObject],
                             from connection: AVCaptureConnection) {
    // TODO: Face detection
    //    superLayer.sublayers?
    //      .filter { $0 is FaceLayer }
    //      .forEach { $0.removeFromSuperlayer() }
    //    guard let faceObject = metadataObjects.filter({ $0.type == .face }).first,
    //          let transformedMetadataObject = previewLayer?.transformedMetadataObject(for: faceObject) else { return }
    //    let faceLayer = FaceLayer(bounds: transformedMetadataObject.bounds)
    //    superLayer.addSublayer(faceLayer)
  }
}

//class FaceLayer: CAShapeLayer {
//
//  init(bounds: CGRect) {
//    super.init()
//    path = UIBezierPath(roundedRect: bounds, cornerRadius: 5).cgPath
//    lineWidth = 1
//    strokeColor = UIColor.yellow.cgColor
//    fillColor = UIColor.clear.cgColor
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//}
