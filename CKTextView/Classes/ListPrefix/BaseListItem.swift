//
//  BaseListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/9/16.
//
//

import UIKit

enum ListType {
    case None, Text, Numbered
}

class BaseListItem: NSObject
{
    var listInfoStore: BaseListInfoStore?
    
    // if a string too long, text must line break. May have two Y!
    var keyYSet: Set<CGFloat> = []
    
    // List link support.
    var prevItem: NumberedListItem?
    var nextItem: NumberedListItem?
    
    func listType() -> ListType {
        return ListType.None
    }
    
    func destory(ckTextView: CKTextView) {
        
    }
    
    func unLinkPrevItem()
    {
        if prevItem != nil {
            prevItem!.unLinkNextItem()
            prevItem = nil
        }
    }
    
    func unLinkNextItem()
    {
        if nextItem != nil {
            nextItem!.unLinkPrevItem()
            nextItem = nil
        }
    }
}
