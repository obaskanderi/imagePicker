//
//  AlbumTableViewController.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-11.
//
//

import UIKit
import Photos

class AlbumTableViewController: UITableViewController {

    private var albums: [PhotoAlbum] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.separatorStyle = .none;
        
        setUpToolbarItems()
        loadAlbums()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onPhotoAlbumUpdated(_:)), name: .PhotoAlbumUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func loadAlbums() {
        // Fetch all albums
        let collectionType: [PHAssetCollectionType] = [.album, .smartAlbum]
        var albumListFetchResult: [PHFetchResult<PHAssetCollection>] = []
        for type in collectionType {
            albumListFetchResult = albumListFetchResult + [PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)]
        }
        
        var tmpAlbumList: [PHAssetCollection] = []
        for fetchResult in albumListFetchResult {
            fetchResult.enumerateObjects({ (album, index, stop) in
                tmpAlbumList.append(album)
            })
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        tmpAlbumList = tmpAlbumList.sorted { $0.localizedTitle! < $1.localizedTitle! }
        for collection in tmpAlbumList {
            var assets: [PhotoAsset] = []
            let fetchResults = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            fetchResults.enumerateObjects({ (object, count, stop) in
                assets.append(PhotoAsset(object))
            })
            
            if assets.count > 0 {
                let album = PhotoAlbum(collection, assets: assets)
                album.indexPath = IndexPath(row: albums.count, section: 0)
                self.albums.append(album)
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumTableViewCell", for: indexPath) as! AlbumTableViewCell
        
        // Configure the cell...
        let album = self.albums[indexPath.row]
        cell.title = album.title
        cell.totalPhotoCount = album.photoCount
        cell.selectedPhotoCount = album.selectedPhotoCount
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        
        let scale = UIScreen.main.scale
        let dimension = CGFloat(70.0)
        let size = CGSize(width: dimension * scale, height: dimension * scale)
        
        PHImageManager.default().requestImage(for: album.thumbnailAsset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
            DispatchQueue.main.async {
                cell.thumbnailImageView.image = image
            }
        }
        
        return cell
    }

    func onPhotoAlbumUpdated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let album = userInfo["PhotoAlbum"] as? PhotoAlbum,
            let indexPath = album.indexPath else { return }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextScene = segue.destination as? AssetCollectionViewController,
            let indexPath = self.tableView.indexPathForSelectedRow {
            let selectedAlbum = self.albums[indexPath.row]
            nextScene.album = selectedAlbum
        }
    }
}
