//
//  UIView+ImagePicker.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-04-19.
//
//

import UIKit

extension UIView {
    func addCornerRadiusAnimation(_ from: CGFloat, to: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        self.layer.add(animation, forKey: "cornerRadius")
        self.layer.cornerRadius = to
    }
}
