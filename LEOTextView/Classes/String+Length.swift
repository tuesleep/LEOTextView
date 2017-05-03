//
//  String+Length.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation

extension String {
    // Return real length of String. it's not absolute equal String.characters.count
    func length() -> Int {
        return NSString(string: self).length
    }
}