//
//  DetectingView.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-18.
//
//

import UIKit

@objc protocol TapDetectingViewDelegate {
    func handleImageViewSingleTap(_ touchPoint: CGPoint)
    func handleImageViewDoubleTap(_ touchPoint: CGPoint)
}

class TapDetectingView: UIImageView {
    weak var delegate: TapDetectingViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.handleImageViewDoubleTap(recognizer.location(in: self))
    }
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.handleImageViewSingleTap(recognizer.location(in: self))
    }
}

private extension TapDetectingView {
    func setup() {
        isUserInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)
    }
}

