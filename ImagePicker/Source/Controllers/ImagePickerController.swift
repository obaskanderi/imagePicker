//
//  ImagePickerController.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-11.
//
//

import UIKit
import Photos

var ImagePickerBundle: Bundle!

public class ImagePickerController: UIViewController {

    public var onFinishedPicking: (([ImagePickerResult]) -> Void)?

    override public func viewDidLoad() {
        super.viewDidLoad()

        var bundle = Bundle(for: type(of: self))
        if let path = bundle.path(forResource: "ImagePicker", ofType: "bundle") {
            bundle = Bundle(path: path)!
        }
        ImagePickerBundle = bundle
        
        let storyboard = UIStoryboard(name: "ImagePicker", bundle: ImagePickerBundle)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "ImagePickerNavigationController") as? UINavigationController else {
            fatalError("navigationController init failed.")
        }
        addChildViewController(navigationController)
        view.addSubview(navigationController.view)
        navigationController.didMove(toParentViewController: self)
        
        SelectedAssetList.shared.removeAll()
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPicking(_:)), name: .FinishedPicking, object: nil)
    }

    func finishedPicking(_ notification: Notification) {
        var results: [ImagePickerResult] = []
        if let userInfo = notification.userInfo, let notificationResults = userInfo["Results"] as? [ImagePickerResult] {
            results = notificationResults
        }
        self.onFinishedPicking?(results)
    }
}
