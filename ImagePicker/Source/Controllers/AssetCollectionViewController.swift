//
//  AssetCollectionViewController.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-12.
//
//

import UIKit
import Photos

private let reuseIdentifier = "AssetCell"

class AssetCollectionViewController: UICollectionViewController {

    var album: PhotoAlbum!
    
    var cellSize: CGSize {
        var numberOfColumns = 7
        
        if self.view.frame.height > self.view.frame.width {
            numberOfColumns = 4
        }
        
        let cellMargin:CGFloat = 2
        let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    let formatter = DateComponentsFormatter()

    fileprivate var imageManager: PHCachingImageManager!
    fileprivate var assetGridThumbnailSize: CGSize = .zero
    fileprivate var previousPreheatRect: CGRect = .zero
    fileprivate var isInitialLoad = true
    fileprivate var viewDidTransition = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpToolbarItems()
        
        self.title = album.title! + (album.selectedPhotoCount > 0 ? " (\(album.selectedPhotoCount))" : "")
        
        self.formatter.unitsStyle = .positional
        self.formatter.allowedUnits = [ .minute, .second ]
        self.formatter.zeroFormattingBehavior = [ .pad ]
        
        let scale: CGFloat = UIScreen.main.scale
        self.assetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        self.imageManager = PHCachingImageManager()
        resetCachedAssets()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onPhotoAssetUpdated(_:)), name: .PhotoAssetUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPhotoAlbumUpdated(_:)), name: .PhotoAlbumUpdated, object: nil)
    }
    
    deinit {
        resetCachedAssets()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateCachedAssets()
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
        
        self.viewDidTransition = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCachedAssets()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        func scrollToBottom() {
            // Calling collectionViewContentSize forces the UICollectionViewLayout to actually render the layout
            _ = self.collectionView?.collectionViewLayout.collectionViewContentSize
            
            // Now you can scroll to your desired indexPath or contentOffset
            self.collectionView?.scrollToItem(at: IndexPath(row: self.album.photoCount - 1, section: 0), at: .bottom, animated: false)
        }
        
        // Only scroll when the view is rendered for the first time
        if self.isInitialLoad {
            self.isInitialLoad = !self.isInitialLoad
            scrollToBottom()
        } else if self.collectionView?.isAtBottom ?? false, self.viewDidTransition {
            self.viewDidTransition = false
            scrollToBottom()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.album.photoCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? AssetCell else {
            fatalError("failed to dequeueReusableCellWithIdentifier \(reuseIdentifier)")
            
        }
        let asset = self.album.assets[indexPath.row]
        
        cell.tag = indexPath.item
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.asset = asset
        
        if asset.isVideo {
            if asset.duration < 3600 {
                self.formatter.allowedUnits = [.minute, .second]
            } else {
                self.formatter.allowedUnits = [.hour, .minute, .second]
            }
            cell.durationLabel.text = formatter.string(from: asset.duration)
        }
        
        self.imageManager.requestImage(for: asset.asset, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil) { (image: UIImage?, info: [AnyHashable : Any]?) in
            if cell.tag == indexPath.item {
                cell.imageView.image = image
                asset.underlyingImage = image
            }
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return cellSize
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = PhotoScrollViewController(photos: album.assets)
        controller.initializePageIndex(indexPath.row)
        controller.delegate = self
        present(controller, animated: true, completion: nil)
        
        // Hack to fix snap back animation when showing PhotoScrollViewController in portait mode
        if self.view.frame.height > self.view.frame.width {
            self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64)
        }
    }
    
    func onPhotoAlbumUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo, let photoAlbum = userInfo["PhotoAlbum"] as? PhotoAlbum, album.id == photoAlbum.id {
            self.title = album.title! + (album.selectedPhotoCount > 0 ? " (\(album.selectedPhotoCount))" : "")
        }
    }
    
    func onPhotoAssetUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo, let asset = userInfo["PhotoAsset"] as? PhotoAsset {
            if asset.album.id == self.album.id {
                if let index = album.assets.index(where: { (entry: PhotoAsset) -> Bool in
                    asset.id == entry.id
                }) {
                    guard let collectionView = self.collectionView else { return }
                    let indexPath = IndexPath(item: index, section: 0)
                    if collectionView.indexPathsForVisibleItems.contains(indexPath) {
                        collectionView.reloadItems(at: [indexPath])
                    }
                }
            }
        }
    }
}

// MARK: - Cache Asset Functions

extension AssetCollectionViewController {
    
    func resetCachedAssets() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = .zero
    }
    
    func updateCachedAssets() {
        let isViewVisible: Bool = self.isViewLoaded && self.view.window != nil
        if !isViewVisible {
            return
        }
        
        // The preheat window is twice the height of the visible rect.
        var preheatRect: CGRect = self.collectionView!.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta: CGFloat = abs(preheatRect.midY - self.previousPreheatRect.midY)
        if delta > self.collectionView!.bounds.height / 3.0 {
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()
            self.computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect,
                                              removedHandler: {(removedRect: CGRect) -> Void in
                                                if let indexPaths = self.collectionView!.indexPathForElementsInRect(removedRect) {
                                                    removedIndexPaths = indexPaths
                                                }
            },
                                              addedHandler: {(addedRect: CGRect) -> Void in
                                                if let indexPaths = self.collectionView!.indexPathForElementsInRect(addedRect) {
                                                    addedIndexPaths = indexPaths
                                                }
            })
            
            // Update the assets the PHCachingImageManager is caching.
            if let cacheManager = self.imageManager {
                if let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths) {
                    cacheManager.startCachingImages(for: assetsToStartCaching, targetSize: self.assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
                }
                
                if let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths) {
                    cacheManager.stopCachingImages(for: assetsToStopCaching, targetSize: self.assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
                }
            }
            
            // Store the preheat rect to compare against in the future.
            self.previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect, andRect newRect: CGRect, removedHandler: (_ removedRect: CGRect) -> Void, addedHandler: (_ addedRect: CGRect) -> Void) {
        if newRect.intersects(oldRect) {
            let oldMaxY: CGFloat = oldRect.maxY
            let oldMinY: CGFloat = oldRect.minY
            let newMaxY: CGFloat = newRect.maxY
            let newMinY: CGFloat = newRect.minY
            if newMaxY > oldMaxY {
                let rectToAdd: CGRect = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd: CGRect = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove: CGRect = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove: CGRect = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        }
        else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset]? {
        if indexPaths.count == 0 {
            return nil
        }
        
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            let asset = self.album.assets[indexPath.row].asset
            assets.append(asset)
        }
        return assets
    }

}

extension AssetCollectionViewController: PhotoScrollViewDelegate {
    
    func didDismiss(_ controller: PhotoScrollViewController) {
    }
    
    func viewForPhoto(_ controller: PhotoScrollViewController, index: Int) -> UIView? {
        if let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? AssetCell {
            return cell.imageView
        }
        return nil
    }
}

extension UICollectionView {
    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }
    
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
    
}
