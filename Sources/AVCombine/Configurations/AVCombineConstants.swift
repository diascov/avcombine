//
//  AVCombineConstants.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 3/26/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import AVFoundation
import UIKit

let constants = AVCombineConstants.shared

struct AVCombineConstants {

  public static let shared = AVCombineConstants()

  private init() { }

  let videoExtensionFormat = "mov"
  let audioExtensionFormat = "m4a" // mp4
  let acceptableVideoExtensions: [AVFileType] = [.mp4, .mov, .m4v]
  let mediaInputQueue = "mediaInputQueue"
  let frameTimescale: Double = 600
  let renderSize = UIScreen.main.nativeBounds.size
  let contentsAnimationKey = "contents"
}
