//
//  ZoomingScrollView.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-18.
//
//

import UIKit
import AVFoundation
import Photos

open class ZoomingScrollView: UIScrollView {
    
    var photo: PhotoAsset! {
        didSet {
            photoImageView.image = nil
            if photo != nil {
                displayImage()
            }
        }
    }
    
    fileprivate(set) var photoImageView: TapDetectingView!
    fileprivate weak var photoBrowser: PhotoScrollViewController?
    fileprivate var tapView: TapDetectingView!
    fileprivate var playButton: UIButton!
    fileprivate var videoPlayer: VideoPlayer!
    fileprivate var playOnReady = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if tapView != nil {
            setup()
        }
    }
    
    convenience init(frame: CGRect, controller: PhotoScrollViewController) {
        self.init(frame: frame)
        self.photoBrowser = controller
        setup()
    }
    
    deinit {
        self.photoBrowser = nil
    }
    
    func setup() {
        // tap
        self.tapView = TapDetectingView(frame: bounds)
        tapView.delegate = self
        tapView.backgroundColor = .clear
        tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(tapView)
        
        // image
        self.photoImageView = TapDetectingView(frame: frame)
        photoImageView.delegate = self
        photoImageView.contentMode = .bottom
        photoImageView.backgroundColor = .clear
        addSubview(photoImageView)

        // self
        self.backgroundColor = .clear
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin]
    }
    
    func initVideoPlayer() {
        guard let photo = self.photo else {
            return
        }
        
        self.videoPlayer = VideoPlayer(photo, delegate: self)
    }
    
    func viewWillAppear() {
    }
    
    func viewWillDisappear() {
    }
    
    
    // MARK: - override
    
    open override func layoutSubviews() {
        tapView.frame = bounds
        
        super.layoutSubviews()
        
        let boundsSize = bounds.size
        var frameToCenter = photoImageView.frame
        
        // horizon
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2)
        } else {
            frameToCenter.origin.x = 0
        }
        
        // vertical
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2)
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center
        if !self.photoImageView.frame.equalTo(frameToCenter) {
            self.photoImageView.frame = frameToCenter
        }
        
        // Video Player
        if let videoPlayer = self.videoPlayer {
            videoPlayer.frame = self.bounds
        }
        
        // Play Button
        if let playButton = self.playButton {
            playButton.center = CGPoint(x: frame.width/2, y: frame.height/2)
        }
    }
    
    open func setMaxMinZoomScalesForCurrentBounds() {
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        guard let photoImageView = self.photoImageView else {
            return
        }
        
        let boundsSize = self.bounds.size
        let imageSize = photoImageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        let minScale: CGFloat = min(xScale, yScale)
        var maxScale: CGFloat = 1.0
        
        let scale = max(UIScreen.main.scale, 2.0)
        let deviceScreenWidth = UIScreen.main.bounds.width * scale // width in pixels. scale needs to remove if to use the old algorithm
        let deviceScreenHeight = UIScreen.main.bounds.height * scale // height in pixels. scale needs to remove if to use the old algorithm
        
        if photoImageView.frame.width < deviceScreenWidth {
            // I think that we should to get coefficient between device screen width and image width and assign it to maxScale. I made two mode that we will get the same result for different device orientations.
            if UIApplication.shared.statusBarOrientation.isPortrait {
                maxScale = deviceScreenHeight / photoImageView.frame.width
            } else {
                maxScale = deviceScreenWidth / photoImageView.frame.width
            }
        } else if photoImageView.frame.width > deviceScreenWidth {
            maxScale = 1.0
        } else {
            // here if photoImageView.frame.width == deviceScreenWidth
            maxScale = 2.5
        }
        
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        self.zoomScale = minScale
        
        // reset position
        photoImageView.frame = CGRect(x: 0, y: 0, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height)
        
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.isScrollEnabled = false
        
        setNeedsLayout()
    }
    
    open func prepareForReuse() {
        self.photo = nil
    }
    
    // MARK: - image
    open func displayImage() {
        // reset scale
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        self.contentSize = CGSize.zero
        
        if let image = self.photo.underlyingImage {
            // image
            self.photoImageView.image = image
            self.photoImageView.contentMode = .scaleAspectFill
            self.photoImageView.backgroundColor = .black
            
            var photoImageViewFrame = CGRect.zero
            photoImageViewFrame.origin = CGPoint.zero
            photoImageViewFrame.size = image.size
            
            self.photoImageView.frame = photoImageViewFrame
            
            self.contentSize = photoImageViewFrame.size
            
            setMaxMinZoomScalesForCurrentBounds()
        }
        
        if self.photo.isVideo {
            
            if self.playButton == nil {
                self.playButton = UIButton(type: .custom)
                playButton.setImage(UIImage(named: "play_button", in: Bundle(for: ImagePickerController.self), compatibleWith: nil), for: UIControlState())
                playButton.setImage(UIImage(named: "play_button_selected", in: Bundle(for: ImagePickerController.self), compatibleWith: nil), for: .highlighted)
                playButton.addTarget(self, action: #selector(onPlayButtonPressed), for: .touchUpInside)
                playButton.sizeToFit()
                playButton.isUserInteractionEnabled = true
                addSubview(playButton)
            }
            
            if self.videoPlayer == nil {
                self.playButton.isEnabled = false
                initVideoPlayer()
            }
        }
        
        setNeedsLayout()
    }
    
    // MARK: - handle tap
    
    open func handleDoubleTap(_ touchPoint: CGPoint) {
        if let photoBrowser = photoBrowser {
            NSObject.cancelPreviousPerformRequests(withTarget: photoBrowser)
        }
        
        if self.photo.isVideo {
            return
        }
        
        if zoomScale > minimumZoomScale {
            // zoom out
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            // zoom in
            let zoomRect = zoomRectForScrollViewWith(maximumZoomScale, touchPoint: touchPoint)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    func onPlayButtonPressed() {
        self.playVideo()
    }
    
    func playVideo() {
        self.playButton.isHidden = true
        self.videoPlayer.play()
    }
    
    func pauseVideo() {
        self.playButton.isHidden = false
        self.videoPlayer.pause()
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingScrollView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.isScrollEnabled = true
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - TapDetectingViewDelegate

extension ZoomingScrollView: TapDetectingViewDelegate {
    
    func handleImageViewSingleTap(_ touchPoint: CGPoint) {
        if self.photo.isVideo, let videoPlayer = self.videoPlayer, videoPlayer.isPlaying() {
            pauseVideo()
        } else {
            self.photo.isSelected = !self.photo.isSelected
        }
    }
    
    func handleImageViewDoubleTap(_ touchPoint: CGPoint) {
        handleDoubleTap(touchPoint)
    }
}

// MARK: - VideoPlayerDelegate

extension ZoomingScrollView: VideoPlayerDelegate {
    
    func onPlayerReady(_ player: VideoPlayer) {
        guard let playerLayer = player.layer() else { return }
        layer.addSublayer(playerLayer)
        playButton.isEnabled = true
        bringSubview(toFront: playButton)
    }
    
    func onPlayerPlaybackDidEnd(_ player: VideoPlayer) {
        self.playButton.isHidden = false
    }
}

// MARK: - Private extension

private extension ZoomingScrollView {
    func getViewFramePercent(_ view: UIView, touch: UITouch) -> CGPoint {
        let oneWidthViewPercent = view.bounds.width / 100
        let viewTouchPoint = touch.location(in: view)
        let viewWidthTouch = viewTouchPoint.x
        let viewPercentTouch = viewWidthTouch / oneWidthViewPercent
        
        let photoWidth = self.photoImageView.bounds.width
        let onePhotoPercent = photoWidth / 100
        let needPoint = viewPercentTouch * onePhotoPercent
        
        var Y: CGFloat!
        
        if viewTouchPoint.y < view.bounds.height / 2 {
            Y = 0
        } else {
            Y = self.photoImageView.bounds.height
        }
        let allPoint = CGPoint(x: needPoint, y: Y)
        return allPoint
    }
    
    func zoomRectForScrollViewWith(_ scale: CGFloat, touchPoint: CGPoint) -> CGRect {
        let w = frame.size.width / scale
        let h = frame.size.height / scale
        let x = touchPoint.x - (h / max(UIScreen.main.scale, 2.0))
        let y = touchPoint.y - (w / max(UIScreen.main.scale, 2.0))
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
