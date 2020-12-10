//
//  AVCombine+Merge.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/12/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import AVFoundation
import UIKit

extension AVCombine {

  public func merge(assets: [AVURLAsset],
                    type: AVCombineAssetType,
                    _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    if assets.isEmpty {
      completion(.failure(.inputParametersError))
    }
    let composition = AVMutableComposition()
    guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
          let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      completion(.failure(.compositionTrackError))
      return
    }
    var insertTime = CMTime(
      seconds: 0,
      preferredTimescale: 1)
    assets.forEach {
      do {
        if let assetVideoTrack = $0.tracks(withMediaType: .video).first,
           let assetAudioTrack = $0.tracks(withMediaType: .audio).first {
          let timeRange = CMTimeRange(
            start: CMTime(
              seconds: 0,
              preferredTimescale: 1),
            duration: $0.duration)
          try videoTrack.insertTimeRange(
            timeRange,
            of: assetVideoTrack,
            at: insertTime)
          try audioTrack.insertTimeRange(
            timeRange,
            of: assetAudioTrack,
            at: insertTime)
          videoTrack.preferredTransform = assetVideoTrack.preferredTransform
        }
        insertTime = insertTime + $0.duration
      } catch {
        completion(.failure(.compositionTrackError))
      }
    }
    export(
      composition: composition,
      videoComposition: nil,
      type: type,
      completion)
  }

  public func merge(videoAsset: AVURLAsset,
                    audioAsset: AVURLAsset,
                    _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    let composition = AVMutableComposition()
    guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
          let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      completion(.failure(.compositionTrackError))
      return
    }
    let insertTime = CMTime(
      seconds: 0,
      preferredTimescale: 1)
    do {
      if let assetVideoTrack = videoAsset.tracks(withMediaType: .video).first,
         let assetAudioTrack = audioAsset.tracks(withMediaType: .audio).first {
        let timeRange = CMTimeRange(
          start: insertTime,
          duration: videoAsset.duration)
        try videoTrack.insertTimeRange(
          timeRange,
          of: assetVideoTrack,
          at: insertTime)
        try audioTrack.insertTimeRange(
          timeRange,
          of: assetAudioTrack,
          at: insertTime)
        videoTrack.preferredTransform = assetVideoTrack.preferredTransform
      }
    } catch {
      completion(.failure(.compositionTrackError))
    }
    export(
      composition: composition,
      videoComposition: nil,
      type: .video,
      completion)
  }
}
