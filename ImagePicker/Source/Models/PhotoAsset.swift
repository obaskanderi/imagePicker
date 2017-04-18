//
//  PhotoAsset.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-17.
//
//

import Foundation
import Photos


class PhotoAsset {
    
    enum Resolution: Int {
        case low    = 0  // 480p
        case medium = 1  // 540p
        case high   = 2  // 720p
        case full   = 3  // 1080p
    }

    weak var album: PhotoAlbum!
    var underlyingImage: UIImage?
    var startTime: Float64 = 0
    var endTime: Float64 = 0
    var avurlAsset: AVURLAsset?
    var resolution: Resolution = .high
    
    var asset: PHAsset {
        didSet {
            endTime = asset.duration
        }
    }
    
    var isSelected: Bool {
        didSet {
            if isSelected {
                SelectedAssetList.shared.add(self)
                album.selectedPhotoCount += 1
            } else {
                SelectedAssetList.shared.remove(self)
                album.selectedPhotoCount -= 1
            }
            NotificationCenter.default.post(name: .PhotoAssetUpdated, object: nil, userInfo: ["PhotoAsset" : self])
        }
    }
    
    var isVideo: Bool {
        get { return mediaType == .video }
    }
    
    var mediaType: PHAssetMediaType {
        get { return asset.mediaType }
    }
    
    var duration: TimeInterval {
        get { return asset.duration }
    }
    
    var id: String {
        get { return asset.localIdentifier }
    }
    
    var dimesnions: CGSize {
        get { return CGSize(width: asset.pixelWidth, height: asset.pixelHeight) }
    }
    
    var aspectRatio: CGFloat {
        get { return CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight) }
    }
    
    var presetName: String {
        get {
            switch resolution {
            case .full:
                return AVAssetExportPreset1920x1080
            case .high:
                return AVAssetExportPreset1280x720
            case .medium:
                return AVAssetExportPreset960x540
            case .low:
                return AVAssetExportPreset640x480
            }
        }
    }
    
    var timeRange: CMTimeRange? {
        get {
            if isVideo {
                let start = CMTimeMakeWithSeconds(startTime, 1000)
                let duration = CMTimeMakeWithSeconds((endTime - startTime), 1000)
                return CMTimeRangeMake(start, duration)
            }
            return nil
        }
    }
    
    init(_ asset: PHAsset, isSelected: Bool = false) {
        self.asset = asset
        self.endTime = asset.duration
        self.isSelected = isSelected
    }
    
    func requestAVURLAsset(_ completion: ((AVURLAsset?) -> Void)? = nil) {
        if let asset = self.avurlAsset {
            completion?(asset)
        } else {
            DispatchQueue.global(qos: .background).async {
                let videoOption = PHVideoRequestOptions()
                videoOption.version = .original
                videoOption.deliveryMode = .fastFormat
                PHImageManager.default().requestAVAsset(forVideo: self.asset, options: videoOption) { (avasset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    DispatchQueue.main.async {
                        guard let avurlAsset = avasset as? AVURLAsset else {
                            completion?(nil)
                            return
                        }
                        self.avurlAsset = avurlAsset
                        completion?(avurlAsset)
                    }
                }
            }
        }
    }

    func loadImage() {
        if self.underlyingImage == nil {
            let option = PHImageRequestOptions()
            option.isNetworkAccessAllowed = true
        
            _ = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 1000, height: 1000), contentMode: .aspectFit, options: option ) { (image, info) -> Void in
                guard let image = image else { return }
                self.underlyingImage = image
            }
        }
    }
}
