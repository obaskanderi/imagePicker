//
//  PhotoScrollViewDelegate.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-19.
//
//

import Foundation

@objc protocol PhotoScrollViewDelegate: class {
    @objc optional func didDismiss(_ controller: PhotoScrollViewController)
    @objc optional func viewForPhoto(_ controller: PhotoScrollViewController, index: Int) -> UIView?
}
