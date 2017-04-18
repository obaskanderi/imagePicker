//
//  VideoHeaderView.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-01.
//
//

import UIKit
import Photos
import ABVideoRangeSlider

protocol VideoHeaderViewDelegate: class {
    func onPreparingThumbnails()
    func onThumbnailsReady()
}

class VideoHeaderView: UIView {
    
    weak var delegate: VideoHeaderViewDelegate?
    
    var asset: PhotoAsset? {
        didSet {
            guard let asset = self.asset else { return }
            slider.asset = asset.asset
            
            slider.startPosition = Float(asset.startTime)
            slider.endPosition = Float(asset.endTime)
        
            if asset.startTime > 0 || asset.endTime < asset.duration {
                slider.colorScheme = UIColor.selectedBlue()
            } else {
                slider.colorScheme = .gray
            }
        }
    }
    
    fileprivate let slider = ABVideoRangeSlider()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        slider.delegate = self
        slider.overlayColor = .black
        slider.colorScheme = .gray
        slider.timeViewBackgroundColor = .clear
        slider.fontColor = .white
        slider.fontSize = 12
        addSubview(slider)

        NotificationCenter.default.addObserver(self, selector: #selector(onVideoPlayerUpdated(_:)), name: .VideoPlayerCurrentTime, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.slider.frame = CGRect(x: 20, y: 40, width: bounds.width - 40, height: 32)
    }
    
    func onVideoPlayerUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo, let currentTime = userInfo["CurrentTime"] as? Float64 {
            self.slider.updateProgressIndicator(currentTime)
        }
    }
}

extension VideoHeaderView: ABVideoRangeSliderDelegate {

    func onPreparingThumbnails() {
        self.delegate?.onPreparingThumbnails()
    }
    
    func onThumbnailsReady() {
        self.delegate?.onThumbnailsReady()
    }
    
    func didChangeValue(_ videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        if startTime > 0 || endTime < videoRangeSlider.duration {
            videoRangeSlider.colorScheme = UIColor.selectedBlue()
        } else {
            videoRangeSlider.colorScheme = .gray
        }
        
        guard let asset = self.asset else { return }
        asset.startTime = startTime
        asset.endTime = endTime
    }
    
    func indicatorDidChangePosition(_ videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        let userInfo: [String : Any] = [ "SliderValue" : Int64(position)]
        NotificationCenter.default.post(name: .VideoScrubberValueChanged, object: nil, userInfo: userInfo)
    }
    
    func sliderGesturesBegan() {
        NotificationCenter.default.post(name: .VideoScrubberStart, object: nil)
    }
    
    func sliderGesturesEnded() {
        NotificationCenter.default.post(name: .VideoScrubberEnd, object: nil)
    }
}
