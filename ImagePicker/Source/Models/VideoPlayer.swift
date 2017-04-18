//
//  VideoPlayer.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-01.
//
//

import Foundation
import AVFoundation
import Photos

@objc protocol VideoPlayerDelegate: class {
    @objc optional func onPlayerPlaybackDidEnd(_ videoPlayer: VideoPlayer)
    @objc optional func onPlayerReady(_ videoPlayer: VideoPlayer)
}

class VideoPlayer: NSObject {
    
    weak var delegate: VideoPlayerDelegate?
    
    var frame: CGRect! {
        didSet {
            guard let playerLayer = self.playerLayer else { return }
            playerLayer.frame = frame
        }
    }
    
    var asset: PhotoAsset! {
        didSet {
            if asset.asset != oldValue.asset {
                self.asset.requestAVURLAsset { (avurlAsset: AVURLAsset?) in
                    if let avasset = avurlAsset {
                        self.avasset = avasset
                    }
                }
            }
        }
    }
    
    var avasset: AVURLAsset! {
        didSet {
            if avasset != oldValue {
               setup()
            }
        }
    }
    
    private let videoOption = PHVideoRequestOptions()
    
    fileprivate var isActive = false
    fileprivate var duration: Float64!
    fileprivate var playerItem: AVPlayerItem!
    fileprivate var player: AVPlayer!
    fileprivate var playerLayer: AVPlayerLayer!
    fileprivate var timeObserver: AnyObject!
    fileprivate var isSeekInProgress = false
    fileprivate var chaseTime = kCMTimeZero
    
    override init() {
        super.init()
        
        self.videoOption.version = .original
        self.videoOption.deliveryMode = .fastFormat
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrubberStart), name: .VideoScrubberStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrubberEnd), name: .VideoScrubberEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrubberValueChanged), name: .VideoScrubberValueChanged, object: nil)
    }
    
    convenience init(_ asset: PhotoAsset, delegate: VideoPlayerDelegate) {
        self.init()
        self.delegate = delegate
        self.asset = asset
        
        self.asset.requestAVURLAsset { (avurlAsset: AVURLAsset?) in
            if let avasset = avurlAsset {
                self.avasset = avasset
            }
        }
    }
    
    convenience init(_ asset: PhotoAsset, avasset: AVURLAsset, delegate: VideoPlayerDelegate) {
        self.init()
        self.delegate = delegate
        self.asset = asset
        self.avasset = avasset
        
        setup()
    }

    deinit {
        cleanup()
        delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if self.player.currentItem?.status == .readyToPlay {
            let seekToTime = CMTimeMake(Int64(asset.startTime), 1)
            stopPlayingAndSeekSmoothlyToTime(seekToTime)
            self.delegate?.onPlayerReady?(self)
        }
    }
    
    private func setup() {
        cleanup()
        self.duration = CMTimeGetSeconds(avasset.duration)
        self.playerItem = AVPlayerItem(asset: avasset)
        self.player = AVPlayer(playerItem: playerItem)
        self.player.actionAtItemEnd = .pause
        self.playerLayer = AVPlayerLayer(player: player)
        
        if self.frame != nil {
            self.playerLayer.frame = frame
        }
        
        self.playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        
        self.timeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main) { [weak self] (elapsedTime: CMTime) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.observeTime(elapsedTime)
        } as AnyObject!
    }

    private func cleanup() {
        if let player = self.player {
            player.pause()
            
            if let observer = self.timeObserver {
                player.removeTimeObserver(observer)
            }
        }
        
        if let layer = playerLayer {
            layer.removeFromSuperlayer()
        }
        
        if let playerItem = self.playerItem {
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    }
    
    func layer() -> CALayer? {
        guard let playerLayer = self.playerLayer else { return nil }
        return playerLayer
    }
    
    @objc func play() {
        guard let player = self.player else { return }
        self.isActive = true
        player.play()
    }
    
    func pause() {
        guard let player = self.player else { return }
        self.isActive = false
        player.pause()
    }
    
    func reset() {
        guard let player = self.player else { return }
        self.isActive = false
        player.pause()
        let seekToTime = CMTimeMake(Int64(self.asset.startTime), 1)
        player.seek(to: seekToTime, completionHandler: { (finished: Bool) in })
    }
    
    func isPlaying() -> Bool {
        guard let player = self.player else {
            return false
        }
        return player.rate > 0
    }
    
    @objc func playerItemDidPlayToEndTime() {
        let startTime = CMTimeMake(Int64(asset.startTime), 1)
        self.player.seek(to: startTime, completionHandler: { (finished: Bool) in
            self.player.pause()
            self.delegate?.onPlayerPlaybackDidEnd?(self)
        })
    }
    
    fileprivate func observeTime(_ elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(player.currentItem!.duration)
        if duration.isFinite {
            var currentTime = CMTimeGetSeconds(self.player.currentTime())
            if Float64(currentTime) >= self.asset.endTime {
                playerItemDidPlayToEndTime()
                currentTime = self.asset.startTime
            }
            
            let userInfo: [String : Any] = ["CurrentTime" : currentTime]
            NotificationCenter.default.post(name: .VideoPlayerCurrentTime, object: self, userInfo: userInfo)
        }
    }
}

// MARK: Handle Scrubbing Notifications

private extension VideoPlayer {
    
    @objc func scrubberStart() {
        if self.isActive {
            self.pause()
            self.isActive = true
        }
    }
    
    @objc func scrubberEnd() {
        if self.isActive {
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(play), userInfo: nil, repeats: false)
        }
    }
    
    @objc func scrubberValueChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo, let seconds = userInfo["SliderValue"] as? Int64 {
            let seekToTime = CMTimeMake(seconds, 1)
            stopPlayingAndSeekSmoothlyToTime(seekToTime)
        }
    }
}

// MARK: Function to help seeking

private extension VideoPlayer {
    
    func stopPlayingAndSeekSmoothlyToTime(_ newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, self.chaseTime) != 0 {
            self.chaseTime = newChaseTime
            if !self.isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    func trySeekToChaseTime() {
        if self.player.status == .readyToPlay {
            actuallySeekToTime()
        }
    }
    
    func actuallySeekToTime() {
        self.isSeekInProgress = true
        let seekTimeInProgress = self.chaseTime
        self.player.seek(to: seekTimeInProgress, toleranceBefore: kCMTimeZero,
                         toleranceAfter: kCMTimeZero, completionHandler:
            { (isFinished:Bool) -> Void in
                if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                    self.isSeekInProgress = false
                } else {
                    self.trySeekToChaseTime()
                }
        })
    }
}
