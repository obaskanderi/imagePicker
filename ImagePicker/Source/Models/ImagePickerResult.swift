//
//  ImagePickerResult.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-11.
//
//

import Foundation
import Photos

public class ImagePickerResult {
    
    public var asset: PHAsset
    public var url: URL?
    
    public var isVideo: Bool {
        get { return asset.mediaType == .video}
    }
    
    public init(_ asset: PHAsset, url: URL? = nil) {
        self.asset = asset
        self.url = url
    }
}
