//
//  UICollectionView+IndexPath.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-17.
//
//

import Foundation

extension UICollectionView {
    func indexPathForElementsInRect(_ rect: CGRect) -> [IndexPath]? {
        let allLayoutAttributes: NSArray = self.collectionViewLayout.layoutAttributesForElements(in: rect)! as NSArray
        if allLayoutAttributes.count == 0 {
            return nil
        }
        
        var indexPaths = [IndexPath]()
        for layoutAttributes in allLayoutAttributes {
            indexPaths.append((layoutAttributes as AnyObject).indexPath! as IndexPath)
        }
        return indexPaths
    }
}
