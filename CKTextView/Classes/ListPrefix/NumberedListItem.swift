//
//  NumberedListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/5/16.
//
//

import UIKit

class NumberedListItem: NSObject {
    var frame: CGRect!
    var number: Int!
    var charLocation: Int!
    
    init(frame: CGRect, number: Int, charLocation: Int)
    {
        super.init()
        
        self.frame = frame
        self.number = number
    }
    
}
