//
//  AVCombine+Generate.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/12/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCombine {

  public func generateVideo(from snapshots: [UIImage],
                            _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    refreshConfiguration(for: .video)
    if snapshots.isEmpty {
      completion(.failure(.inputParametersError))
    }
    self.snapshots = snapshots
    let queue = DispatchQueue(label: constants.mediaInputQueue)
    assetWriterInput?.requestMediaDataWhenReady(on: queue) {
      if self.didAppendPixelBuffers() {
        self.assetWriterInput?.markAsFinished()
        self.assetWriter?.finishWriting {
          if let url = self.url {
            completion(.success(AVURLAsset(url: url)))
          } else {
            completion(.failure(.dataError))
          }
        }
      }
    }
  }

  public func generateVideo(from snapshot: UIImage,
                            duration: CMTime,
                            _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    refreshConfiguration(for: .video)
    self.snapshots.append(snapshot)
    let queue = DispatchQueue(label: constants.mediaInputQueue)
    assetWriterInput?.requestMediaDataWhenReady(on: queue) {
      let frameDuration = CMTimeGetSeconds(duration)
      if self.didAppendPixelBuffers(frameDuration: frameDuration) {
        self.assetWriterInput?.markAsFinished()
        self.assetWriter?.finishWriting {
          if let url = self.url {
            completion(.success(AVURLAsset(url: url)))
          } else {
            completion(.failure(.dataError))
          }
        }
      }
    }
  }
}
