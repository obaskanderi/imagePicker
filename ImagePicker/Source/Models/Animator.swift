//
//  Animator.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-19.
//
//

import Foundation
import UIKit

@objc protocol PhotoAnimatorDelegate {
    func willPresent(_ browser: PhotoScrollViewController)
    func willDismiss(_ browser: PhotoScrollViewController)
}

class Animator: NSObject, PhotoAnimatorDelegate {
    var resizableImageView: UIImageView?
    
    var senderOriginImage: UIImage!
    var senderViewOriginalFrame: CGRect = .zero
    var senderViewForAnimation: UIView?
    
    var finalImageViewFrame: CGRect = .zero

    var bounceAnimation: Bool = false
    var animationDuration: TimeInterval  = 0.35
    var animationDamping: CGFloat = 1.0
    
    func willPresent(_ browser: PhotoScrollViewController) {
        guard let sender = browser.delegate?.viewForPhoto?(browser, index: browser.initialPageIndex) ?? senderViewForAnimation else {
            presentAnimation(browser)
            return
        }
        
        guard let appWindow = UIApplication.shared.delegate?.window, let window = appWindow else { return }
        
        let imageFromView = (senderOriginImage ?? browser.getImageFromView(sender)).rotateImageByOrientation()
        let imageRatio = imageFromView.size.width / imageFromView.size.height
        
        self.senderViewOriginalFrame = calcOriginFrame(sender)
        self.finalImageViewFrame = calcFinalFrame(imageRatio)
        
        self.resizableImageView = UIImageView(image: imageFromView)
        resizableImageView!.frame = senderViewOriginalFrame
        resizableImageView!.clipsToBounds = true
        resizableImageView!.contentMode = .scaleAspectFill
        if sender.layer.cornerRadius != 0 {
            let duration = (animationDuration * Double(animationDamping))
            resizableImageView!.layer.masksToBounds = true
            resizableImageView!.addCornerRadiusAnimation(sender.layer.cornerRadius, to: 0, duration: duration)
        }
        window.addSubview(resizableImageView!)
        
        presentAnimation(browser)
    }
    
    func willDismiss(_ controller: PhotoScrollViewController) {
        guard let sender = controller.delegate?.viewForPhoto?(controller, index: controller.currentPageIndex) ?? senderViewForAnimation,
            let image = controller.photoAtIndex(controller.currentPageIndex).underlyingImage,
            let scrollView = controller.pageDisplayedAtIndex(controller.currentPageIndex) else {
                senderViewForAnimation?.isHidden = false
                controller.dismissPhotoBrowser(animated: false)
                return
        }
        
        self.senderViewForAnimation = sender
        controller.view.isHidden = true
        controller.backgroundView.isHidden = false
        controller.backgroundView.alpha = 1
        
        self.senderViewOriginalFrame = calcOriginFrame(sender)
        
        let contentOffset = scrollView.contentOffset
        let scrollFrame = scrollView.photoImageView.frame
        let offsetY = scrollView.center.y - (scrollView.bounds.height/2)
        let frame = CGRect(
            x: scrollFrame.origin.x - contentOffset.x,
            y: scrollFrame.origin.y + contentOffset.y + offsetY,
            width: scrollFrame.width,
            height: scrollFrame.height)
        
        resizableImageView!.image = image.rotateImageByOrientation()
        resizableImageView!.frame = frame
        resizableImageView!.alpha = 1.0
        resizableImageView!.clipsToBounds = true
        resizableImageView!.contentMode = .scaleAspectFill
        if let view = senderViewForAnimation , view.layer.cornerRadius != 0 {
            let duration = (animationDuration * Double(animationDamping))
            resizableImageView!.layer.masksToBounds = true
            resizableImageView!.addCornerRadiusAnimation(0, to: view.layer.cornerRadius, duration: duration)
        }
        
        dismissAnimation(controller)
    }
}

private extension Animator {
    func calcOriginFrame(_ sender: UIView) -> CGRect {
        if let senderViewOriginalFrameTemp = sender.superview?.convert(sender.frame, to:nil) {
            return senderViewOriginalFrameTemp
        } else if let senderViewOriginalFrameTemp = sender.layer.superlayer?.convert(sender.frame, to: nil) {
            return senderViewOriginalFrameTemp
        } else {
            return .zero
        }
    }
    
    func calcFinalFrame(_ imageRatio: CGFloat) -> CGRect {
        if Measurement.screenRatio < imageRatio {
            let width = Measurement.screenWidth
            let height = width / imageRatio
            let yOffset = (Measurement.screenHeight - height) / 2
            return CGRect(x: 0, y: yOffset, width: width, height: height)
        } else {
            let height = Measurement.screenHeight
            let width = height * imageRatio
            let xOffset = (Measurement.screenWidth - width) / 2
            return CGRect(x: xOffset, y: 0, width: width, height: height)
        }
    }
}

private extension Animator {
    func presentAnimation(_ browser: PhotoScrollViewController, completion: ((Void) -> Void)? = nil) {
        browser.view.isHidden = true
        browser.view.alpha = 0.0
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: animationDamping,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions(),
            animations: {
                browser.backgroundView.alpha = 1.0
                self.resizableImageView?.frame = self.finalImageViewFrame
            },
            completion: { (Bool) -> Void in
                browser.view.isHidden = false
                browser.view.alpha = 1.0
                browser.backgroundView.isHidden = true
                
                self.resizableImageView?.alpha = 0.0
        })
    }
    
    func dismissAnimation(_ browser: PhotoScrollViewController, completion: ((Void) -> Void)? = nil) {
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: animationDamping,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions(),
            animations: {
                browser.backgroundView.alpha = 0.0
                self.resizableImageView?.layer.frame = self.senderViewOriginalFrame
            },
            completion: { (Bool) -> () in
                browser.dismissPhotoBrowser(animated: true) {
                    self.resizableImageView?.removeFromSuperview()
                }
        })
    }
}

