//
//  AVCombine+Crop.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/25/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import AVFoundation

extension AVCombine {

  public func crop(asset: AVURLAsset,
                   type: AVCombineAssetType,
                   startTime: Double,
                   endTime: Double,
                   _ completion: @escaping (Result<AVURLAsset, AVCombineError>) -> Void) {
    let avAsset = AVAsset(url: asset.url)
    export(
      asset: avAsset,
      type: type,
      startTime: startTime,
      endTime: endTime,
      videoComposition: nil,
      completion)
  }
}
