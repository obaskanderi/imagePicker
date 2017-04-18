//
//  PagingScrollView.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-18.
//
//

import Foundation

class PagingScrollView: UIScrollView {
    
    let pageIndexTagOffset: Int = 1000
    let sideMargin: CGFloat = 10
    fileprivate var visiblePages = [ZoomingScrollView]()
    fileprivate var recycledPages = [ZoomingScrollView]()
    
    fileprivate weak var controller: PhotoScrollViewController?
    var numberOfPhotos: Int {
        return controller?.photos.count ?? 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isPagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
    }
    
    convenience init(frame: CGRect, controller: PhotoScrollViewController) {
        self.init(frame: frame)
        self.controller = controller
        
        updateFrame(bounds, currentPageIndex: controller.currentPageIndex)
    }
    
    func reload() {
        self.visiblePages.forEach({$0.removeFromSuperview()})
        self.visiblePages.removeAll()
        self.recycledPages.removeAll()
    }
    
    func loadAdjacentPhotosIfNecessary(_ photo: PhotoAsset, currentPageIndex: Int) {
        guard let controller = self.controller, let page = pageDisplayingAtPhoto(photo) else {
            return
        }
        let pageIndex = (page.tag - self.pageIndexTagOffset)
        if currentPageIndex == pageIndex {
            // Previous
            if pageIndex > 0 {
                let previousPhoto = controller.photos[pageIndex - 1]
                if previousPhoto.underlyingImage == nil {
                    previousPhoto.loadImage()
                }
            }
            // Next
            if pageIndex < self.numberOfPhotos - 1 {
                let nextPhoto = controller.photos[pageIndex + 1]
                if nextPhoto.underlyingImage == nil {
                    nextPhoto.loadImage()
                }
            }
        }
    }
    
    func animate(_ frame: CGRect) {
        setContentOffset(CGPoint(x: frame.origin.x - sideMargin, y: 0), animated: false)
    }
    
    func updateFrame(_ bounds: CGRect, currentPageIndex: Int) {
        var frame = bounds
        frame.origin.x -= self.sideMargin
        frame.size.width += (2 * self.sideMargin)
        
        self.frame = frame
        
        if self.visiblePages.count > 0 {
            for page in self.visiblePages {
                let pageIndex = page.tag - self.pageIndexTagOffset
                page.frame = frameForPageAtIndex(pageIndex)
                page.setMaxMinZoomScalesForCurrentBounds()
            }
        }
        
        updateContentSize()
        updateContentOffset(currentPageIndex)
    }
    
    func updateContentSize() {
        contentSize = CGSize(width: bounds.size.width * CGFloat(numberOfPhotos), height: bounds.size.height)
    }
    
    func updateContentOffset(_ index: Int) {
        let pageWidth = bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        contentOffset = CGPoint(x: newOffset, y: 0)
    }
    
    func tilePages() {
        guard let controller = controller else { return }
        
        let firstIndex: Int = getFirstIndex()
        let lastIndex: Int = getLastIndex()
        
        self.visiblePages
            .filter({ $0.tag - pageIndexTagOffset < firstIndex ||  $0.tag - pageIndexTagOffset > lastIndex })
            .forEach { page in
                recycledPages.append(page)
                page.prepareForReuse()
                page.removeFromSuperview()
        }
        
        let visibleSet: Set<ZoomingScrollView> = Set(visiblePages)
        let visibleSetWithoutRecycled: Set<ZoomingScrollView> = visibleSet.subtracting(recycledPages)
        self.visiblePages = Array(visibleSetWithoutRecycled)
        
        while self.recycledPages.count > 2 {
            self.recycledPages.removeFirst()
        }
        
        for index: Int in firstIndex...lastIndex {
            if self.visiblePages.contains(where: ({ $0.tag - pageIndexTagOffset == index })) {
                continue
            }
            
            let page: ZoomingScrollView = ZoomingScrollView(frame: frame, controller: controller)
            page.frame = frameForPageAtIndex(index)
            page.tag = index + pageIndexTagOffset
            page.photo = controller.photos[index]
            
            self.visiblePages.append(page)
            addSubview(page)
        }
    }
    
    func pageDisplayedAtIndex(_ index: Int) -> ZoomingScrollView? {
        for page in self.visiblePages {
            if page.tag - self.pageIndexTagOffset == index {
                return page
            }
        }
        return nil
    }
    
    func pageDisplayingAtPhoto(_ photo: PhotoAsset) -> ZoomingScrollView? {
        for page in self.visiblePages {
            if page.photo === photo {
                return page
            }
        }
        return nil
    }
}

private extension PagingScrollView {
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + self.sideMargin
        return pageFrame
    }
    
    func getFirstIndex() -> Int {
        let firstIndex = Int(floor((bounds.minX + self.sideMargin * 2) / bounds.width))
        if firstIndex < 0 {
            return 0
        }
        if firstIndex > self.numberOfPhotos - 1 {
            return self.numberOfPhotos - 1
        }
        return firstIndex
    }
    
    func getLastIndex() -> Int {
        let lastIndex  = Int(floor((bounds.maxX - self.sideMargin * 2 - 1) / bounds.width))
        if lastIndex < 0 {
            return 0
        }
        if lastIndex > self.numberOfPhotos - 1 {
            return self.numberOfPhotos - 1
        }
        return lastIndex
    }
}
