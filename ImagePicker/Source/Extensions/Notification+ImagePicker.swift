//
//  Notification+ImagePicker.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-18.
//
//

import Foundation

extension Notification.Name {
    static let SelectedAssetListUpdated = Notification.Name("SelectedAssetListUpdated")
    static let FinishedPicking = Notification.Name("FinishedPicking")
    static let PhotoAssetUpdated = Notification.Name("PhotoAssetUpdated")
    static let PhotoAlbumUpdated = Notification.Name("PhotoAlbumUpdated")
    static let VideoScrubberStart = Notification.Name("VideoScrubberStart")
    static let VideoScrubberEnd = Notification.Name("VideoScrubberEnd")
    static let VideoScrubberValueChanged = Notification.Name("VideoScrubberValueChanged")
    static let VideoPlayerCurrentTime = Notification.Name("VideoProgress")
}
