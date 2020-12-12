//
//  AVCombine+Export.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/25/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import AVFoundation

extension AVCombine {

  func export(composition: AVMutableComposition,
              videoComposition: AVMutableVideoComposition?,
              type: AVCombineAssetType,
              _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    export(
      asset: composition,
      type: type,
      startTime: nil,
      endTime: nil,
      videoComposition: videoComposition,
      completion)
  }

  func export(asset: AVAsset,
              type: AVCombineAssetType,
              startTime: Double?,
              endTime: Double?,
              videoComposition: AVVideoComposition?,
              _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    guard let url = uniqueUrl(for: type) else { return }
    if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
      exportSession.outputURL = url
      exportSession.outputFileType = .mp4
      exportSession.shouldOptimizeForNetworkUse = true
      exportSession.videoComposition = videoComposition
      if let startTime = startTime, let endTime = endTime {
        let timeRange = CMTimeRange(
          start: CMTime(seconds: startTime, preferredTimescale: 1000),
          end: CMTime(seconds: endTime, preferredTimescale: 1000))
        exportSession.timeRange = timeRange
      }
      exportSession.exportAsynchronously {
        switch exportSession.status {
        case .failed, .cancelled:
          if let error = exportSession.error {
            completion(.failure(.customError(error.localizedDescription)))
          }
        default:
          let asset = AVURLAsset(url: url)
          completion(.success(asset))
        }
      }
    } else {
      completion(.failure(.assetExportSessionError))
    }
  }
}
