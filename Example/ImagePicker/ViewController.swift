//
//  ViewController.swift
//  ImagePicker
//
//  Created by Omair Baskanderi on 2017-05-12.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import ImagePicker
import Photos
import AVKit
import Agrume

private let reuseIdentifier = "Cell"

class ViewController: UICollectionViewController {

    let formatter = DateComponentsFormatter()
    
    var results: [ImagePickerResult] = []
    var fetchOptions = PHImageRequestOptions()
    
    var cellSize: CGSize {
        var numberOfColumns = 7
        if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
            numberOfColumns = 4
        }
        let cellMargin:CGFloat = 2
        let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.formatter.unitsStyle = .positional
        self.formatter.allowedUnits = [ .minute, .second ]
        self.formatter.zeroFormattingBehavior = [ .pad ]
        
        self.fetchOptions.isNetworkAccessAllowed = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
        
    }
    
    @IBAction func onSelectPhotosPressed(_ sender: Any) {
        let picker = ImagePickerController()
        picker.onFinishedPicking = onFinishedPicking
        present(picker, animated: true, completion: nil)
    }

    func onFinishedPicking(_ results: [ImagePickerResult]) {
        print("Selected \(results.count) assets")
        for result in results {
            print("asset.localIdentifier: \(result.asset.localIdentifier)")
        }
        self.results = results
        self.collectionView?.reloadData()
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? CollectionViewCell else {
            fatalError("failed to dequeueReusableCellWithIdentifier \(reuseIdentifier)")
            
        }
        cell.tag = indexPath.item
        
        let result = results[indexPath.row]
        cell.result = result
        
        if let videoURL = result.url, result.isVideo {
            let avurlAsset = AVURLAsset(url: videoURL)
            let duration = CMTimeGetSeconds(avurlAsset.duration)
            
            if duration < 3600 {
                self.formatter.allowedUnits = [.minute, .second]
            } else {
                self.formatter.allowedUnits = [.hour, .minute, .second]
            }
            cell.durationLabel.text = formatter.string(from: duration)
        }
        
        let _ = PHCachingImageManager.default().requestImage(for: result.asset, targetSize: CGSize(width: 400, height: 400), contentMode: .aspectFit, options: self.fetchOptions) { (fetchedImage: UIImage?, info: [AnyHashable : Any]?) in
            guard let image = fetchedImage else { return }
            DispatchQueue.main.async {
                if cell.tag == indexPath.item {
                    cell.imageView.image = image
                }
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let result = results[indexPath.row]
        if let videoURL = result.url, result.isVideo {
            let player = AVPlayer(url: videoURL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true, completion:  nil)
        } else {
            let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
            if let image = cell.imageView.image {
                let agrume = Agrume(image: image, backgroundColor: .black)
                agrume.hideStatusBar = true
                agrume.showFrom(self)
            }
        }
    }
}
