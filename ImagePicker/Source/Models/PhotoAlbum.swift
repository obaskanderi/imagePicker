//
//  Album.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-13.
//
//

import Foundation
import Photos

class PhotoAlbum {
    
    var collection: PHAssetCollection
    var assets: [PhotoAsset]
    var indexPath: IndexPath?
    
    var id: String {
        get { return collection.localIdentifier }
    }
    
    var selectedPhotoCount: Int = 0 {
        didSet {
            NotificationCenter.default.post(name: .PhotoAlbumUpdated, object: nil, userInfo: ["PhotoAlbum" : self])
        }
    }
    
    var title: String? {
        get { return collection.localizedTitle }
    }
    
    var thumbnailAsset: PHAsset {
        get { return assets[assets.count - 1].asset }
    }
    
    var photoCount: Int {
        get { return assets.count }
    }
    
    init(_ collection: PHAssetCollection, assets: [PhotoAsset]) {
        self.collection = collection
        self.assets = assets
        
        for asset in assets {
            asset.album = self
        }
    }
}
