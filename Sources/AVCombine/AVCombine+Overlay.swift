//
//  AVCombine+Overlay.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/25/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCombine {

  public func add(overlays: [AVCombineOverlay],
                  in asset: AVURLAsset,
                  _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    let composition = AVMutableComposition()
    guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID()),
          let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID()) else {
      completion(.failure(.compositionTrackError))
      return
    }
    do {
      if let assetVideoTrack = asset.tracks(withMediaType: .video).first,
         let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
        let frameRange = CMTimeRange(
          start: .zero,
          duration: asset.duration)
        try videoTrack.insertTimeRange(
          frameRange,
          of: assetVideoTrack, at: .zero)
        try audioTrack.insertTimeRange(
          frameRange,
          of: assetAudioTrack,
          at: .zero)
        videoTrack.preferredTransform = assetVideoTrack.preferredTransform
      }
    } catch {
      completion(.failure(.compositionTrackError))
    }
    // Combine layers
    let outputLayer = CALayer()
    outputLayer.frame = CGRect(
      x: 0,
      y: 0,
      width: videoTrack.naturalSize.width,
      height: videoTrack.naturalSize.height)
    let videolayer = CALayer()
    videolayer.frame = CGRect(
      origin: .zero,
      size: constants.renderSize)
    videolayer.opacity = 1
    outputLayer.addSublayer(videolayer)
    overlays.forEach { overlay in
      switch overlay.type {
      case .images:
        let overlayLayer = CALayer()
        let animation = CAKeyframeAnimation(keyPath: constants.contentsAnimationKey)
        animation.values = overlay.images.map { $0.cgImage! }
        animation.duration = overlay.duration
        animation.repeatCount = .greatestFiniteMagnitude
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        overlayLayer.add(animation, forKey: constants.contentsAnimationKey)
        overlayLayer.setPosition(from: overlay, videoTrack: videoTrack)
        outputLayer.addSublayer(overlayLayer)
      case .text:
        let textLayer = CATextLayer()
        let mutableAttributedString = NSMutableAttributedString(attributedString: overlay.attributedString)
        overlay.attributedString.enumerateAttribute(
          .font,
          in: NSRange(
            location: 0,
            length: overlay.attributedString.length),
          options: .longestEffectiveRangeNotRequired) { (value, range, _) in
          if let oldFont = value as? UIFont {
            let newFont = oldFont.withSize(oldFont.pointSize * UIScreen.main.scale)
            mutableAttributedString.removeAttribute(
              .font,
              range: range)
            mutableAttributedString.addAttribute(
              .font,
              value: newFont,
              range: range)
          }
        }
        textLayer.string = mutableAttributedString
        textLayer.cornerRadius = overlay.cornerRadius
        textLayer.backgroundColor = overlay.backgroundColor.cgColor
        textLayer.alignmentMode = overlay.alignment
        textLayer.setPosition(
          from: overlay,
          videoTrack: videoTrack)
        outputLayer.addSublayer(textLayer)
      case .drawing:
        let drawingLayer = CALayer()
        drawingLayer.contents = overlay.contents
        drawingLayer.masksToBounds = true
        drawingLayer.setPosition(
          from: overlay,
          videoTrack: videoTrack)
        outputLayer.addSublayer(drawingLayer)
      }
    }
    let layercomposition = AVMutableVideoComposition()
    layercomposition.frameDuration = CMTime(
      value: 1,
      timescale: 30)
    layercomposition.renderSize = constants.renderSize
    layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videolayer,
      in: outputLayer)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(
      start: .zero,
      duration: composition.duration)
    let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    layerinstruction.applyTransform(track: videoTrack)
    instruction.layerInstructions = [layerinstruction]
    layercomposition.instructions = [instruction]
    export(
      composition: composition,
      videoComposition: layercomposition,
      type: .video,
      completion)
  }
}

extension AVMutableVideoCompositionLayerInstruction {

  func applyTransform(track: AVMutableCompositionTrack) {
    let standardFrame = CGRect(origin: .zero, size: track.naturalSize)
    let transformedFrame = standardFrame.applying(track.preferredTransform)
    let xScale = constants.renderSize.width / transformedFrame.size.width
    let yCoordinate = constants.renderSize.height / transformedFrame.size.height
    let scale = CGAffineTransform(scaleX: xScale, y: yCoordinate)
    let transform = track.preferredTransform.concatenating(scale)
    setTransform(transform, at: .zero)
  }
}

extension CALayer {

  func setPosition(from overlay: AVCombineOverlay, videoTrack: AVMutableCompositionTrack) {
    let scale: CGFloat = overlay.type == .drawing ? 1 : UIScreen.main.scale
    let proportionDifference = UIScreen.main.bounds.size.height * UIScreen.main.scale - videoTrack.naturalSize.width
    let overlayWidth = overlay.size.width * scale
    let overlayHeight = overlay.size.height * scale
    let coordinatePoint = overlay.type == .drawing ? .zero : overlay.center
    let overlayCoordinateX = overlay.type == .drawing ? coordinatePoint.x * scale : coordinatePoint.x * scale - overlayWidth / 2
    let overlayCoordinateY = overlay.type == .drawing ? coordinatePoint.y * scale : coordinatePoint.y * scale - overlayHeight / 2
    frame = CGRect(
      x: overlayCoordinateX,
      y: videoTrack.naturalSize.width - overlayCoordinateY - overlayHeight + proportionDifference,
      width: overlayWidth,
      height: overlayHeight)
    if let transform = overlay.transform {
      let mirroredTransform = CGAffineTransform(
        a: transform.a,
        b: -transform.b,
        c: -transform.c,
        d: transform.d,
        tx: transform.tx,
        ty: transform.ty)
      setAffineTransform(mirroredTransform)
    }
  }
}
