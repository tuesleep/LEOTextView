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
    
    var firstKeyY: CGFloat?
    
    // if a string too long, text must line break. May have two Y!
    var keyYSet: Set<CGFloat> = []
    
    // List link support.
    var prevItem: NumberedListItem?
    var nextItem: NumberedListItem?
    
    func listType() -> ListType {
        return ListType.None
    }
    
    /// Usually override this method to perform additional things about destory.
    ///
    /// Must call super in your implementation.
    func destory(ckTextView: CKTextView, byBackspace: Bool) {
        // Backspace destory this item.
        if byBackspace {
            if prevItem == nil {
                // Oh, I am first item of list.
                if nextItem != nil {
                    // Next item exist, it become first item of list.
                    nextItem!.unLinkPrevItem()
                } else {
                    // Not next item, destory BezierPath.
                    self.listInfoStore?.clearBezierPath(ckTextView)
                }
            } else {
                if nextItem != nil {
                    prevItem!.linkNextItem(nextItem!)
                }
                
                prevItem!.unLinkNextItem()
            }
        } else {
            // Destory by other way, no link operate.
            prevItem?.unLinkNextItem()
            nextItem?.unLinkPrevItem()
        }
    }
    
    func unLinkPrevItem()
    {
        
    }
    
    func unLinkNextItem()
    {
        
    }
    
    func linkPrevItem(item: BaseListItem)
    {
        
    }
    
    func linkNextItem(item: BaseListItem)
    {
        
    }
}
