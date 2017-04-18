//
//  AssetCell.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-12.
//
//

import UIKit
import Photos

class AssetCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var checkmarkImageView: UIImageView!
    @IBOutlet var checkmarkView: UIView!
    
    var asset: PhotoAsset? = nil {
        didSet {
            guard let asset = self.asset else {
                self.mediaType = nil
                self.checkmarkImageView.image = nil
                return
            }
            self.mediaType = asset.mediaType
            updateCheckmarkImage(asset.isSelected)
            isSelected = asset.isSelected
        }
    }
    
    fileprivate var mediaType: PHAssetMediaType? = nil {
        didSet {
            guard let mediaType = self.mediaType else {
                self.iconImageView.isHidden = true
                self.durationLabel.isHidden = true
                return
            }
            let isHidden = (mediaType != .video)
            self.iconImageView.isHidden = isHidden
            self.durationLabel.isHidden = isHidden
        }
    }
    
    static fileprivate let checkmarkImage = UIImage(named: "check_white", in: ImagePickerBundle, compatibleWith: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCheckmarkPressed))
        self.checkmarkView.addGestureRecognizer(tap)
    
        self.checkmarkImageView.layer.cornerRadius = checkmarkImageView.frame.size.width / 2
        self.checkmarkImageView.layer.borderWidth = 1
        self.checkmarkImageView.layer.borderColor = UIColor.white.cgColor
        self.checkmarkImageView.tintColor = .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.asset = nil
    }
    
    func onCheckmarkPressed() {
        isSelected = !isSelected
        self.asset?.isSelected = isSelected
        updateCheckmarkImage(isSelected)
    }
    
    private func updateCheckmarkImage(_ isEnabled: Bool) {
        if isEnabled {
            self.checkmarkImageView.backgroundColor = .green
            self.checkmarkImageView.image = AssetCell.checkmarkImage
        } else {
            self.checkmarkImageView.backgroundColor = .clear
            self.checkmarkImageView.image = nil
        }
    }
}
