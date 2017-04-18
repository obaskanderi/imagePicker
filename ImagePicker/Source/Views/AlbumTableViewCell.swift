//
//  AlbumTableViewCell.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-12.
//
//

import UIKit

class AlbumTableViewCell: UITableViewCell {
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var albumTitleLabel: UILabel!
    @IBOutlet var albumCountLabel: UILabel!
    @IBOutlet var selectedCountLabel: UILabel!
    
    var title: String! {
        didSet {
            albumTitleLabel.text = title
        }
    }
    
    var totalPhotoCount: Int = 0 {
        didSet {
            albumCountLabel.text = "\(totalPhotoCount)"
        }
    }
    
    var selectedPhotoCount: Int = 0 {
        didSet {
            if selectedPhotoCount > 0 {
                selectedCountLabel.text = "\(selectedPhotoCount)"
                selectedCountLabel.sizeToFit()
            }
            selectedCountLabel.isHidden = (selectedPhotoCount == 0)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedCountLabel.layer.cornerRadius = selectedCountLabel.frame.width / 2
        self.selectedCountLabel.layer.masksToBounds = true
        self.selectedCountLabel.backgroundColor = UIColor.selectedBlue()
    }
}
