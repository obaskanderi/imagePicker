//
//  SelectedAssetList.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-17.
//
//

import Foundation
import Photos

class SelectedAssetList {
    
    static let shared = SelectedAssetList()
    
    var assets: [PhotoAsset] = []
    
    var count: Int {
        get { return assets.count }
    }

    var isEmpty: Bool {
        get { return assets.isEmpty }
    }
    
    func add(_ asset: PhotoAsset) {
        assets.append(asset)
        NotificationCenter.default.post(name: .SelectedAssetListUpdated, object: self)
    }

    func remove(_ asset: PhotoAsset) {
        if let index = assets.index(where: { (entry: PhotoAsset) -> Bool in
            asset.id == entry.id
        }) {
            assets.remove(at: index)
            NotificationCenter.default.post(name: .SelectedAssetListUpdated, object: self)
        }
    }
    
    func removeAll() {
        assets.removeAll()
    }
}
