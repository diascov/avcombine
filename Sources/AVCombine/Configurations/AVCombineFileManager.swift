//
//  AVCombineManager.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 3/26/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

import AVFoundation

public protocol AVCombineFileManager: class {
  func remove(asset: AVURLAsset) throws
  func removeAsset(at url: URL) throws
  func uniqueUrl(for type: AVCombineAssetType) -> URL?
}

extension AVCombineFileManager {

  private var fileManager: FileManager {
    return FileManager.default
  }

  public func uniqueUrl(for type: AVCombineAssetType) -> URL? {
    var format = ""
    switch type {
    case .audio: format = constants.audioExtensionFormat
    case .video: format = constants.videoExtensionFormat
    }
    guard let url = try? fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true) else { return nil }
    let uniqueUrl = url.appendingPathComponent(NSUUID().uuidString).appendingPathExtension(format)
    return uniqueUrl
  }

  public func remove(asset: AVURLAsset) throws {
    do {
      try fileManager.removeItem(at: asset.url)
    } catch {
      throw error
    }
  }

  public func removeAsset(at url: URL) throws {
    do {
      try fileManager.removeItem(at: url)
    } catch {
      throw error
    }
  }
}
