//
//  AVCombine.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 3/26/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import UIKit
import AVFoundation

public final class AVCombine: AVCombineFileManager {

  var fps: Double = 30
  var url: URL?
  var snapshots = [UIImage]()

  var assetWriter: AVAssetWriter?
  var assetWriterInput: AVAssetWriterInput?
  var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

  var frameNumber = 0

  public init() {}

  func refreshConfiguration(for type: AVCombineAssetType) {
    url = uniqueUrl(for: type)
    guard let url = url else { return }
    assetWriter = try? AVAssetWriter(url: url, fileType: .mov)
    let outputSettings = setOutputSettings()
    assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
    guard let assetWriter = assetWriter,
          let assetWriterInput = assetWriterInput else { return }
    if assetWriter.canAdd(assetWriterInput) {
      assetWriter.add(assetWriterInput)
    }
    let sourcePixelBufferAttributes = setSourcePixelBufferAttributes()
    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: assetWriterInput,
      sourcePixelBufferAttributes: sourcePixelBufferAttributes)

    if !assetWriter.startWriting() { return }
    assetWriter.startSession(atSourceTime: .zero)
  }

  private func setOutputSettings() -> [String: Any] {
    let renderSize = constants.renderSize
    return [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: renderSize.width,
      AVVideoHeightKey: renderSize.height
    ]
  }

  private func setSourcePixelBufferAttributes() -> [String: NSNumber] {
    let renderSize = constants.renderSize
    return [
      kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
      kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSize.width)),
      kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSize.height))
    ]
  }
}
