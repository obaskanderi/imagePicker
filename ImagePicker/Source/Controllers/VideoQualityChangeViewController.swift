//
//  VideoQualityChangeViewController.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-05.
//
//

import UIKit
import Foundation
import AVFoundation
import TGPControls

class VideoQualityChangeViewController: UIViewController {

    var asset: PhotoAsset! {
        didSet {
            let filename = asset.id.toLocalIdentifier() + ".mov"
            let exportPath = NSTemporaryDirectory().appendingFormat(filename)
            self.exportURL = URL(fileURLWithPath: exportPath)
            
            if let container = self.videoContainer {
                container.image = asset.underlyingImage
            }
            
            asset.requestAVURLAsset { (avurlAsset: AVURLAsset?) in
                self.exportVideo(self.asset.resolution)
            }
            
            if let slider = self.slider {
                slider.value = CGFloat(asset.resolution.rawValue)
            }
        }
    }
    
    fileprivate var videoPlayer: VideoPlayer!
    fileprivate var exportURL: URL!
    fileprivate var exportAsset: AVURLAsset!
    fileprivate var exportSession: AVAssetExportSession!
    fileprivate var selectedResolution: PhotoAsset.Resolution!
    fileprivate var progressView: UIView!
    fileprivate let formatter = ByteCountFormatter()
    
    fileprivate var isExportingVideo = false {
        didSet {
            guard let view = self.progressView, let container = self.videoContainer else { return  }
            view.isHidden = !isExportingVideo
            container.bringSubview(toFront: view)
        }
    }
    
    @IBOutlet var videoContainer: UIImageView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var slider: TGPDiscreteSlider!
    @IBOutlet var qualityLabel: UILabel!
    
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.asset.avurlAsset = self.exportAsset
        self.asset.resolution = self.selectedResolution
        dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.slider.ticksListener = self
        
        if let asset = self.asset {
            self.slider.value = CGFloat(asset.resolution.rawValue)
            self.videoContainer.image = asset.underlyingImage
        }
        
        self.progressView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        progressView.isOpaque = false
        progressView.backgroundColor = .black
        progressView.alpha = 0.60
        progressView.layer.cornerRadius = progressView.frame.width / 4
        progressView.layer.masksToBounds = true
        progressView.isHidden = !isExportingVideo
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.startAnimating()
        spinner.center = progressView.center
        progressView.addSubview(spinner)
        
        self.videoContainer.addSubview(progressView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let player = self.videoPlayer {
            player.frame = CGRect(x: 0, y: 0, width: self.videoContainer.frame.width, height: self.videoContainer.frame.height)
        }
        self.progressView.center = CGPoint(x: self.videoContainer.frame.width/2 , y: self.videoContainer.frame.height/2)
    }
    
    private func dismiss() {
        if let session = self.exportSession, session.status == .exporting {
            session.cancelExport()
        }
        self.videoPlayer.reset()
        self.dismiss(animated: true, completion: nil)
    }
    
    func exportVideo(_ resolution: PhotoAsset.Resolution) {
        self.isExportingVideo = true
        
        if let videoPlayer = self.videoPlayer, videoPlayer.isPlaying() {
            videoPlayer.pause()
        }
        
        let newResolution = resolution
        var presetString: String = ""
        var presetName: String = ""
        switch resolution {
        case .low:
            presetName = AVAssetExportPreset640x480
            presetString = "480p"
        case .medium:
            presetName = AVAssetExportPreset960x540
            presetString = "540p"
        case .high:
            presetName = AVAssetExportPreset1280x720
            presetString = "720p"
        case .full:
            presetName = AVAssetExportPreset1920x1080
            presetString = "1080p"
        }
        
        do {
            if FileManager.default.fileExists(atPath: self.exportURL.path) {
                try FileManager.default.removeItem(at: self.exportURL)
            }
        } catch {
            print("Failed to remove file at path: \(self.exportURL.path)")
        }
        
        self.exportSession = AVAssetExportSession(asset: asset.avurlAsset!, presetName: presetName)
        guard let exporter = exportSession else { return }
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                do {
                    let attr = try FileManager.default.attributesOfItem(atPath: self.exportURL.path)
                    let fileSize = attr[FileAttributeKey.size] as! Int64
                    self.qualityLabel.text = "\(presetString) (~\(self.formatter.string(fromByteCount: fileSize)))"
                    self.qualityLabel.sizeToFit()
                } catch {
                    print("Failed to get file attributes at path: \(self.exportURL.path)")
                }
                
                switch(exporter.status) {
                case .completed:
                    self.exportAsset = AVURLAsset(url: self.exportURL)
                    if let player = self.videoPlayer {
                        player.avasset = self.exportAsset
                    } else {
                        self.videoPlayer = VideoPlayer(self.asset, avasset: self.exportAsset, delegate: self)
                    }
                    self.selectedResolution = newResolution
                case .cancelled:
                    self.isExportingVideo = false
                    print("Cancelled!!")
                case .exporting:
                    self.isExportingVideo = false
                    print("Exporting")
                case .failed:
                    self.isExportingVideo = false
                    print("Failed, error = \(String(describing: exporter.error))")
                case .unknown:
                    self.isExportingVideo = false
                    print("Unknown")
                case .waiting:
                    self.isExportingVideo = false
                    print("Waiting")
                }
            }
        })
    }
}

extension VideoQualityChangeViewController: VideoPlayerDelegate {
    
    func onPlayerReady(_ videoPlayer: VideoPlayer) {
        guard let playerLayer = videoPlayer.layer() else { return }
        playerLayer.masksToBounds = true
        self.videoContainer.layer.addSublayer(playerLayer)
        self.videoPlayer.play()
        self.isExportingVideo = false
    }
    
    func onPlayerPlaybackDidEnd(_ videoPlayer: VideoPlayer) {
        self.videoPlayer.reset()
        self.videoPlayer.play()
    }
}

extension VideoQualityChangeViewController: TGPControlsTicksProtocol {
    
    func tgpTicksDistanceChanged(ticksDistance: CGFloat, sender: AnyObject) { }
    
    func tgpValueChanged(value: UInt) {
        if let resolution = PhotoAsset.Resolution(rawValue: Int(value)) {
            exportVideo(resolution)
        }
    }
}
