//
//  PhotoScrollViewController.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-19.
//
//

import UIKit
import AVFoundation

class PhotoScrollViewController: UIViewController {

    let pageIndexTagOffset: Int = 1000
    
    // toolbar
    fileprivate var toolbar: UIToolbar!
    fileprivate var backButton: UIBarButtonItem!
    fileprivate var sendButton: UIBarButtonItem!
    fileprivate var qualityBarButton: UIBarButtonItem!
    fileprivate var spacerButton: UIBarButtonItem!
    fileprivate var qualityButton: UIButton!
    
    // actions
    fileprivate var activityViewController: UIActivityViewController!
    fileprivate var panGesture: UIPanGestureRecognizer!
    
    // tool for controls
    fileprivate var applicationWindow: UIWindow!
    fileprivate lazy var pagingScrollView: PagingScrollView = PagingScrollView(frame: self.view.frame, controller: self)
    
    // checkmarks and counter views
    fileprivate var checkmarkImageView: UIImageView!
    fileprivate var selectedCountLabel: UILabel!
    
    var backgroundView: UIView!
    
    var initialPageIndex: Int = 0
    var currentPageIndex: Int = 0
    
    // for status check property
    fileprivate var isEndAnimationByToolBar: Bool = true
    fileprivate var isViewActive: Bool = false
    fileprivate var isPerformingLayout: Bool = false
    
    // pangesture property
    fileprivate var firstX: CGFloat = 0.0
    fileprivate var firstY: CGFloat = 0.0
    
    // timer
    fileprivate var controlVisibilityTimer: Timer!
    
    // delegate
    fileprivate let animator = Animator()
    open weak var delegate: PhotoScrollViewDelegate?
    
    // video scrubber
    fileprivate let headerView = VideoHeaderView()
    
    // photos
    var photos: [PhotoAsset] = []
    var numberOfPhotos: Int {
        return photos.count
    }
    
    // disabel status bar for controller
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK - Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    public convenience init(photos: [PhotoAsset]) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
    }
    
    public convenience init(originImage: UIImage, photos: [PhotoAsset], animatedFromView: UIView) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
        animator.senderOriginImage = originImage
        animator.senderViewForAnimation = animatedFromView
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setup() {
        guard let window = UIApplication.shared.delegate?.window else {
            return
        }
        applicationWindow = window
        
        modalPresentationCapturesStatusBarAppearance = true
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureAppearance()
        configureToolbar()
        updateCheckmark(photoAtIndex(initialPageIndex))
        
        NotificationCenter.default.addObserver(self, selector: #selector(onPhotoAssetUpdated(_:)), name: .PhotoAssetUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSelectedListUpdated(_:)), name: .SelectedAssetListUpdated, object: nil)
        
        self.animator.willPresent(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.isPerformingLayout = true
        
        self.pagingScrollView.updateFrame(view.bounds, currentPageIndex: currentPageIndex)
        
        self.headerView.frame = frameForHeaderAtOrientation()
        updateHeaderAndToolbar()
        
        self.toolbar.frame = frameForToolbarAtOrientation()
        self.checkmarkImageView.frame = frameForCheckmarkAtOrientation()
        self.selectedCountLabel.frame = frameForCountLabelAtOrientation()
        self.selectedCountLabel.layer.cornerRadius = selectedCountLabel.frame.width / 2
        
        self.isPerformingLayout = false
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.isViewActive = true
    }
    
    func reloadData() {
        performLayout()
        self.view.setNeedsLayout()
    }
    
    func performLayout() {
        self.isPerformingLayout = true
        
        // reset local cache
        self.pagingScrollView.reload()
        
        // reframe
        self.pagingScrollView.updateContentOffset(currentPageIndex)
        self.pagingScrollView.tilePages()
        
        self.isPerformingLayout = false
    }
    
    func prepareForClosePhotoBrowser() {
        self.applicationWindow.removeGestureRecognizer(panGesture)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    func dismissPhotoBrowser(animated: Bool, completion: ((Void) -> Void)? = nil) {
        prepareForClosePhotoBrowser()
        
        if animated {
            self.modalTransitionStyle = .crossDissolve
        }
        
        dismiss(animated: animated) {
            completion?()
        }
    }

    func close() {
        self.delegate?.didDismiss?(self)
        self.animator.willDismiss(self)
    }
}

extension PhotoScrollViewController {
    
    func initializePageIndex(_ index: Int) {
        var i = index
        if index >= numberOfPhotos {
            i = numberOfPhotos - 1
        }
        
        self.initialPageIndex = i
        self.currentPageIndex = i
        
        if isViewLoaded {
            jumpToPageAtIndex(index)
            if !isViewActive {
                self.pagingScrollView.tilePages()
            }
        }
    }
    
    func jumpToPageAtIndex(_ index: Int) {
        if index < numberOfPhotos {
            if !isEndAnimationByToolBar {
                return
            }
            self.isEndAnimationByToolBar = false
            
            let pageFrame = frameForPageAtIndex(index)
            self.pagingScrollView.animate(pageFrame)
        }
    }
    
    func photoAtIndex(_ index: Int) -> PhotoAsset {
        return photos[index]
    }
    
    func gotoPreviousPage() {
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    func gotoNextPage() {
        jumpToPageAtIndex(currentPageIndex + 1)
    }
}

private extension PhotoScrollViewController {
    func configureAppearance() {
        self.view.backgroundColor = .black
        self.view.clipsToBounds = true
        self.view.isOpaque = false
        
        self.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: Measurement.screenWidth, height: Measurement.screenHeight))
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0.0
        
        self.applicationWindow.addSubview(backgroundView)
        
        self.pagingScrollView.delegate = self
        self.view.addSubview(pagingScrollView)
        
        self.checkmarkImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        checkmarkImageView.layer.cornerRadius = checkmarkImageView.frame.size.width / 2
        checkmarkImageView.layer.borderWidth = 1
        checkmarkImageView.layer.borderColor = UIColor.white.cgColor
        checkmarkImageView.tintColor = .white
        self.view.addSubview(checkmarkImageView)
        
        self.selectedCountLabel = UILabel()
        selectedCountLabel.textAlignment = .center
        selectedCountLabel.text = "\(SelectedAssetList.shared.count)"
        selectedCountLabel.font = UIFont.systemFont(ofSize: 16)
        selectedCountLabel.layer.masksToBounds = true
        selectedCountLabel.layer.borderWidth = 2
        selectedCountLabel.layer.borderColor = UIColor.white.cgColor
        selectedCountLabel.textColor = .white
        selectedCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        selectedCountLabel.isHidden = SelectedAssetList.shared.count == 0
        selectedCountLabel.sizeToFit()
        self.view.addSubview(selectedCountLabel)
        
        self.headerView.delegate = self
        self.headerView.backgroundColor = .black
        self.view.addSubview(headerView)

        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        self.view.addGestureRecognizer(panGesture)
    }
    
    func configureToolbar() {
        self.toolbar = UIToolbar(frame: frameForToolbarAtOrientation())
        toolbar.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toolbar.clipsToBounds = true
        toolbar.isTranslucent = true
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        
        self.backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(close))
        backButton.tintColor = .white
        
        self.sendButton = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(onSendPressed))
        sendButton.tintColor = .white
        sendButton.isEnabled = SelectedAssetList.shared.count > 0
        
        self.spacerButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.qualityButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 25))
        qualityButton.layer.borderWidth = 2
        qualityButton.layer.borderColor = UIColor.white.cgColor
        qualityButton.setTitleColor(.white, for: .normal)
        qualityButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        qualityButton.addTarget(self, action: #selector(onQualityPressed), for: .touchUpInside)
        qualityBarButton = UIBarButtonItem(customView: qualityButton)
        
        self.view.addSubview(toolbar)
    }
    
    func updateHeaderAndToolbar() {
        self.headerView.frame.origin.y = -(self.headerView.frame.height * 2)
        let photo = photoAtIndex(self.currentPageIndex)
        if photo.isVideo {
            headerView.asset = photo
            
            var resolutionString = ""
            switch photo.resolution {
            case .full:
                resolutionString = "1080"
            case .high:
                resolutionString = "720"
            case .medium:
                resolutionString = "540"
            case .low:
                resolutionString = "480"
            }
            
            self.qualityButton.setTitle(resolutionString, for: .normal)
            self.toolbar.setItems([backButton, spacerButton, qualityBarButton, spacerButton, sendButton], animated: true)
        } else {
            self.toolbar.setItems([backButton, spacerButton, sendButton], animated: true)
        }
    }
    
    func updateCheckmark(_ asset: PhotoAsset) {
        if asset.isSelected {
            self.checkmarkImageView.backgroundColor = .green
            self.checkmarkImageView.image = UIImage.checkmark()
        } else {
            self.checkmarkImageView.backgroundColor = .clear
            self.checkmarkImageView.image = nil
        }
        checkmarkImageView.frame = frameForCheckmarkAtOrientation()
    }
    
    @objc func onQualityPressed() {
        let controller = VideoQualityChangeViewController(nibName: "VideoQualityChangeViewController", bundle: ImagePickerBundle)
        controller.asset = photoAtIndex(self.currentPageIndex)
        present(controller, animated: true)
    }
    
    @objc func onPhotoAssetUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo, let asset = userInfo["PhotoAsset"] as? PhotoAsset {
            if let index = self.photos.index(where: { (entry: PhotoAsset) -> Bool in
                asset.id == entry.id
            }) {
                if self.currentPageIndex == index {
                    updateCheckmark(asset)
                }
            }
        }
    }
    
    @objc func onSelectedListUpdated(_ notification: Notification) {
        self.selectedCountLabel.text = "\(SelectedAssetList.shared.count)"
        self.selectedCountLabel.isHidden = SelectedAssetList.shared.count == 0
        self.sendButton.isEnabled = SelectedAssetList.shared.count > 0
    }
    
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = self.pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + 10
        return pageFrame
    }
    
    func frameForToolbarAtOrientation() -> CGRect {
        let currentOrientation = UIApplication.shared.statusBarOrientation
        var height: CGFloat = self.navigationController?.navigationBar.frame.size.height ?? 44
        if UIInterfaceOrientationIsLandscape(currentOrientation) {
            height = 32
        }
        return CGRect(x: 0, y: self.view.bounds.size.height - height, width: self.view.bounds.size.width, height: height)
    }
    
    func frameForCheckmarkAtOrientation() -> CGRect {
        let width = checkmarkImageView.frame.width
        let height = checkmarkImageView.frame.height
        let photo = photoAtIndex(currentPageIndex)
        
        var yPos: CGFloat = 15
        if photo.isVideo {
            yPos += 70
        }
        
        return CGRect(x: self.view.bounds.size.width - width - 15, y: yPos, width: width, height: height)
    }
    
    func frameForCountLabelAtOrientation() -> CGRect {
        let width: CGFloat = 40
        let height: CGFloat = 40
        return CGRect(x: self.view.bounds.size.width - width - 15, y: self.view.bounds.size.height - self.toolbar.frame.size.height - height - 35, width: width, height: height)
    }
    
    func frameForHeaderAtOrientation() -> CGRect {
        return CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 80)
    }
}

internal extension PhotoScrollViewController {
    
    func pageDisplayedAtIndex(_ index: Int) -> ZoomingScrollView? {
        return pagingScrollView.pageDisplayedAtIndex(index)
    }
    
    func getImageFromView(_ sender: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sender.frame.size, true, 0.0)
        sender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        guard let zoomingScrollView: ZoomingScrollView = pagingScrollView.pageDisplayedAtIndex(currentPageIndex), !self.headerView.frame.contains(sender.location(in: self.view)) else {
            return
        }
        
        self.backgroundView.isHidden = true
        self.checkmarkImageView.isHidden = true
        
        let photo = photoAtIndex(currentPageIndex)
        if photo.isVideo {
            self.headerView.isHidden = true
        }
        
        let viewHeight: CGFloat = zoomingScrollView.frame.size.height
        let viewHalfHeight: CGFloat = viewHeight/2
        var translatedPoint: CGPoint = sender.translation(in: self.view)
        
        // gesture began
        if sender.state == .began {
            firstX = zoomingScrollView.center.x
            firstY = zoomingScrollView.center.y
            setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
        zoomingScrollView.center = translatedPoint
        
        let minOffset: CGFloat = viewHalfHeight / 4
        let offset: CGFloat = 1 - (zoomingScrollView.center.y > viewHalfHeight
            ? zoomingScrollView.center.y - viewHalfHeight
            : -(zoomingScrollView.center.y - viewHalfHeight)) / viewHalfHeight
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(max(0.7, offset))
        
        // gesture end
        if sender.state == .ended {
            
            if zoomingScrollView.center.y > viewHalfHeight + minOffset
                || zoomingScrollView.center.y < viewHalfHeight - minOffset {
                
                self.backgroundView.backgroundColor = view.backgroundColor
                close()
            } else {
                self.checkmarkImageView.isHidden = false
                if photo.isVideo {
                    self.headerView.isHidden = false
                }
                
                // Continue Showing View
                setNeedsStatusBarAppearanceUpdate()
                
                let velocityY: CGFloat = CGFloat(0.35) * sender.velocity(in: self.view).y
                let finalX: CGFloat = firstX
                let finalY: CGFloat = viewHalfHeight
                
                let animationDuration: Double = Double(abs(velocityY) * 0.0002 + 0.2)
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                self.view.backgroundColor = .black
                zoomingScrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
            }
        }
    }
}

// MARK: - VideoHeaderViewDelegate

extension PhotoScrollViewController: VideoHeaderViewDelegate {
    
    func onPreparingThumbnails() {
        DispatchQueue.main.async {
            self.headerView.frame.origin.y = -(self.headerView.frame.height * 2)
        }
    }
    
    func onThumbnailsReady() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.headerView.frame.origin.y = 0
                self.view.bringSubview(toFront: self.headerView)
            })
        }
    }
}

// MARK: - UIScrollView Delegate

extension PhotoScrollViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isViewActive else {
            return
        }
        guard !isPerformingLayout else {
            return
        }
        
        // tile page
        self.pagingScrollView.tilePages()
        
        // Calculate current page
        let previousCurrentPage = currentPageIndex
        let visibleBounds = pagingScrollView.bounds
        self.currentPageIndex = min(max(Int(floor(visibleBounds.midX / visibleBounds.width)), 0), numberOfPhotos - 1)
        
        if currentPageIndex != previousCurrentPage {
            if let page = pageDisplayedAtIndex(currentPageIndex) {
                page.viewWillAppear()
            }
            
            if let page = pageDisplayedAtIndex(previousCurrentPage) {
                page.viewWillDisappear()
            }
            
            updateHeaderAndToolbar()
            updateCheckmark(photos[currentPageIndex])
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.isEndAnimationByToolBar = true
    }
}
