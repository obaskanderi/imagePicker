//
//  String+Filename.swift
//  Pods
//
//  Created by Omair Baskanderi on 2017-05-11.
//
//

import Foundation

extension String {

    func toLocalIdentifier() -> String {
        if (isEmpty) {
            return ""
        }
        var localIdentifer = self.components(separatedBy: "/")[0]
        if localIdentifer[localIdentifer.startIndex] == "/" {
            localIdentifer.remove(at: localIdentifer.startIndex)
        }
        return localIdentifer
    }

}
