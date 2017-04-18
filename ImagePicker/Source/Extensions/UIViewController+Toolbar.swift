//
// UIViewController+ImagePicker.swift
// Pods
//
// Created by Omair Baskanderi on 2017-04-11
//
//
import AVFoundation

extension UIViewController {
    
    // MARK: - Toolbar
    
    func setUpToolbarItems() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbarItems), name: NSNotification.Name.SelectedAssetListUpdated, object: nil)
        updateToolbarItems()
    }
    
    func updateToolbarItems() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sendButton = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(onSendPressed))
        
        if SelectedAssetList.shared.count > 0 {
            let countView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
            countView.backgroundColor = UIColor.selectedBlue()
            countView.layer.cornerRadius = countView.frame.width / 2
            
            let countLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            countLabel.text = "\(SelectedAssetList.shared.count)"
            countLabel.textColor = .white
            countLabel.sizeToFit()
            countLabel.center = countView.center
            countView.addSubview(countLabel)
            
            let countButton = UIBarButtonItem(customView: countView)
            self.toolbarItems = [cancelButton, spacer, countButton, sendButton]
        } else {
            sendButton.isEnabled = false
            self.toolbarItems = [cancelButton, spacer, sendButton]
        }
    }
    
    func onCancelPressed() {
        SelectedAssetList.shared.removeAll()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func onSendPressed() {
        let progress = RPCircularProgress()
        progress.frame = CGRect(x: 40, y: 15, width: 30, height: 30)
        progress.thicknessRatio = 0.2
        progress.indeterminateDuration = 1
        progress.trackTintColor = .clear
        progress.progressTintColor = UIColor.selectedBlue()
        progress.indeterminateProgress = 0
        progress.enableIndeterminate()
        
        let importAlert = UIAlertController(title: "Processing...", message: nil, preferredStyle: .alert)
        importAlert.view.addSubview(progress)
        
        present(importAlert, animated: true, completion: nil)
        
        var resetProgress = false
        func updateProgress() {
            progress.clockwiseProgress = !resetProgress
            progress.updateProgress(resetProgress ? 0 : 1, animated: true, initialDelay: 0, duration: 1, completion: updateProgress)
            resetProgress = !resetProgress
        }
        updateProgress()
        
        processSelectedAssets {
            importAlert.dismiss(animated: true, completion: nil)
        }
    }
    
    func processSelectedAssets(_ completion: @escaping () -> Void) {
        var results: [ImagePickerResult] = []
        
        func checkFinished() {
            if SelectedAssetList.shared.isEmpty {
                let userInfo: [String : Any] = ["Results" : results]
                NotificationCenter.default.post(name: .FinishedPicking, object: nil, userInfo: userInfo)
            
                if let childViewController = self.presentingViewController {
                    if let parentViewController = childViewController.presentingViewController {
                        parentViewController.dismiss(animated: true, completion: nil)
                    } else {
                        childViewController.dismiss(animated: true, completion: nil)
                    }
                }
                completion()
            }
        }
        
        for asset in SelectedAssetList.shared.assets {
            if asset.isVideo {
                asset.requestAVURLAsset({ (avurlAsset: AVURLAsset?) in
                    if let avurlAsset = avurlAsset {
                        self.handleVideoAsset(asset, avurlAsset: avurlAsset, completion: { (result: ImagePickerResult?) in
                            if let result = result {
                                results.append(result)
                            }
                            SelectedAssetList.shared.remove(asset)
                            checkFinished()
                        })
                    }
                })
            } else {
                results.append(ImagePickerResult(asset.asset))
                SelectedAssetList.shared.remove(asset)
                checkFinished()
            }
        }
    }
    
    func handleVideoAsset(_ asset: PhotoAsset, avurlAsset: AVURLAsset, completion: @escaping (ImagePickerResult?) -> Void) {
        let filename = asset.id.toLocalIdentifier() + ".mov"
        let exportPath = NSTemporaryDirectory().appendingFormat(filename)
        let exportURL = URL(fileURLWithPath: exportPath)
        
        do {
            if FileManager.default.fileExists(atPath: exportURL.path) {
                try FileManager.default.removeItem(at: exportURL)
            }
        } catch {
            print("Failed to remove file at path: \(exportURL.path)")
        }
            
        let session = AVAssetExportSession(asset: avurlAsset, presetName: asset.presetName)
        guard let exportSession = session else { return }
        exportSession.outputURL = exportURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        if let timeRange = asset.timeRange {
            exportSession.timeRange = timeRange
        }
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                var result: ImagePickerResult! = nil
                switch(exportSession.status) {
                case .completed:
                    result = ImagePickerResult(asset.asset, url: exportURL)
                    break
                default:
                    print("Export Failed error: \(String(describing: exportSession.error))")
                    break
                }
                completion(result)
            }
        }
    }
}
