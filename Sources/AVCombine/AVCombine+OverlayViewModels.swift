//
//  AVCombine+OverlayViewModels.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/25/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import UIKit
import AVFoundation

public struct AVCombineOverlayImages: AVCombineOverlay {

  public var type: AVCombineOverlayType
  public var center: CGPoint
  public var size: CGSize
  public var transform: CGAffineTransform?

  public let images: [UIImage]
  public let duration: Double

  public init(type: AVCombineOverlayType,
              center: CGPoint,
              size: CGSize,
              transform: CGAffineTransform?,
              images: [UIImage],
              duration: Double) {
    self.type = type
    self.center = center
    self.size = size
    self.transform = transform
    self.images = images
    self.duration = duration
  }
}

public struct AVCombineOverlayText: AVCombineOverlay {

  public var type: AVCombineOverlayType
  public var center: CGPoint
  public var size: CGSize
  public var transform: CGAffineTransform?

  public let attributedString: NSAttributedString
  public let cornerRadius: CGFloat
  public let backgroundColor: UIColor
  public let alignment: CATextLayerAlignmentMode

  public init(type: AVCombineOverlayType,
              center: CGPoint,
              size: CGSize,
              transform: CGAffineTransform?,
              attributedString: NSAttributedString,
              cornerRadius: CGFloat,
              backgroundColor: UIColor,
              alignment: CATextLayerAlignmentMode) {
    self.type = type
    self.center = center
    self.size = size
    self.transform = transform
    self.attributedString = attributedString
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.alignment = alignment
  }
}

public struct AVCombineOverlayDrawing: AVCombineOverlay {

  public var type: AVCombineOverlayType
  public var size: CGSize
  public var transform: CGAffineTransform?

  public let contents: Any?

  public init(type: AVCombineOverlayType,
              size: CGSize,
              transform: CGAffineTransform?,
              contents: Any?) {
    self.type = type
    self.size = size
    self.transform = transform
    self.contents = contents
  }
}

public protocol AVCombineOverlay {
  var type: AVCombineOverlayType { get }
  var size: CGSize { get }
  var transform: CGAffineTransform? { get }

  var images: [UIImage] { get }
  var duration: Double { get }

  var attributedString: NSAttributedString { get }
  var cornerRadius: CGFloat { get }
  var backgroundColor: UIColor { get }
  var alignment: CATextLayerAlignmentMode { get }

  var contents: Any? { get }

  var center: CGPoint { get }
  var origin: CGPoint { get }
}

extension AVCombineOverlay {
  public var images: [UIImage] { return [UIImage]() }
  public var duration: Double { return 0 }
  public var attributedString: NSAttributedString { return NSAttributedString(string: "") }
  public var cornerRadius: CGFloat { return 0 }
  public var backgroundColor: UIColor { return .clear }
  public var alignment: CATextLayerAlignmentMode { return .center }
  public var contents: Any? { return nil }
  public var center: CGPoint { return .zero }
  public var origin: CGPoint { return .zero }
}

public enum AVCombineOverlayType {
  case images
  case text
  case drawing
}

public enum AVCombineAssetType: String {
  case audio
  case video
}
