//
//  NumberedListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/5/16.
//
//

import UIKit

class NumberedListItem: BaseListItem {
    
    var label: UILabel!
    var number: Int!
    
    init(keyY: CGFloat, label: UILabel, bezierPath: UIBezierPath, number: Int)
    {
        super.init()
        
        self.keyYSet.insert(keyY)
        self.label = label
        self.bezierPath = bezierPath
        self.number = number
    }
    
    override func listType() -> ListType {
        return ListType.Numbered
    }
    
    override func unLinkPrevItem() {
        super.unLinkPrevItem()
    }
    
    override func unLinkNextItem() {
        super.unLinkNextItem()
    }
    
    
}
