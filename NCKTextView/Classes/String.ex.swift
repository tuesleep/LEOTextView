//
//  String.ex.swift
//  Pods
//
//  Created by Chanricle King on 13/09/2016.
//
//

import Foundation

extension String {
    // Return real length of String. it's not absolute equal String.characters.count
    func length() -> Int {
        return NSString(string: self).length
    }
}
