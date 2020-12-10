//
//  AVCombineError.swift
//  AVCombine
//
//  Created by Dmitrii Iascov on 6/12/20.
//  Copyright © 2020 Dmitrii Iascov. All rights reserved.
//

public enum AVCombineError: Error {
  case inputParametersError
  case dataError
  case compositionTrackError
  case assetExportSessionError
  case assetError
  case customError(String)
}
