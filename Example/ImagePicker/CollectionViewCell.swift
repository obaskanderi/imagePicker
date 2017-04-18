//
//  CollectionViewCell.swift
//  ImagePicker
//
//  Created by Omair Baskanderi on 2017-05-12.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import ImagePicker

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    
    var result: ImagePickerResult! = nil {
        didSet {
            guard let asset = self.result else { return }
            iconImageView.isHidden = !asset.isVideo
            durationLabel.isHidden = !asset.isVideo
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        result = nil
    }
    
}
