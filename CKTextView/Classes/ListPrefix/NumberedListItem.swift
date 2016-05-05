//
//  NumberedListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/5/16.
//
//

import UIKit

class NumberedListItem: NSObject {
    // if a string too long, text must line break. May have two Y!
    var keyYSet: Set<CGFloat> = []
    var label: UILabel!
    var bezierPath: UIBezierPath!
    
    var number: Int!
    
    var prevItem: NumberedListItem?
    var nextItem: NumberedListItem?
    
    init(keyY: CGFloat, label: UILabel, bezierPath: UIBezierPath, number: Int)
    {
        super.init()
        
        self.keyYSet.insert(keyY)
        self.label = label
        self.bezierPath = bezierPath
        self.number = number
    }
}
