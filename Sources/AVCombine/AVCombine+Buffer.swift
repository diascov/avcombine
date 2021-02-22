//
//  AVCombine+Buffer.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/27/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCombine {

  func didAppendPixelBuffers() -> Bool {
    let frameDuration = CMTime(
      value: Int64(constants.frameTimescale / fps),
      timescale: Int32(constants.frameTimescale))
    while !snapshots.isEmpty {
      if !isReadyForData {
        return false
      }
      let snapshot = snapshots.removeFirst()
      let presentationTime = CMTimeMultiply(
        frameDuration,
        multiplier: Int32(frameNumber))
      let success = appendImage(
        snapshot,
        withPresentationTime: presentationTime)
      if success {
        frameNumber += 1
      }
    }
    return true
  }

  func didAppendPixelBuffers(frameDuration: Double) -> Bool {
    if !isReadyForData {
      return false
    }
    let snapshot = snapshots.removeFirst()
    let startTime = CMTimeMake(
      value: 0,
      timescale: Int32(constants.frameTimescale))
    let endTime = CMTimeMakeWithSeconds(
      Float64(frameDuration / 2),
      preferredTimescale: Int32(constants.frameTimescale))
    return appendImage(snapshot, startTime: startTime, endTime: endTime)
  }

  private var isReadyForData: Bool {
    return assetWriterInput?.isReadyForMoreMediaData ?? false
  }

  private func appendImage(_ image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
    guard let pixelBuffer = pixelBuffer(from: image) else { return false }
    return pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: presentationTime) ?? false
  }

  private func appendImage(_ image: UIImage, startTime: CMTime, endTime: CMTime) -> Bool {
    guard let pixelBuffer = pixelBuffer(from: image) else { return false }
    return pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: startTime) ?? false
      && pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: endTime) ?? false
  }

  func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
    let attrs = [
      kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
      kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
    ] as CFDictionary
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      Int(image.size.width),
      Int(image.size.height),
      kCVPixelFormatType_32ARGB,
      attrs, &pixelBuffer)
    guard status == kCVReturnSuccess,
          let buffer = pixelBuffer else { return nil }
    CVPixelBufferLockBaseAddress(
      buffer,
      CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }
    context.setAlpha(0.01)
    context.setFillColor(UIColor.clear.cgColor)
    context.translateBy(x: 0, y: image.size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    UIGraphicsPushContext(context)
    image.draw(
      in: CGRect(
        x: 0,
        y: 0,
        width: image.size.width,
        height: image.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(
      buffer,
      CVPixelBufferLockFlags(rawValue: 0))
    return pixelBuffer
  }
}
