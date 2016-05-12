//
//  BaseListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/9/16.
//
//

import UIKit

enum ListType {
    case Text, Numbered, Bulleted
}

class BaseListItem: NSObject
{
    var listInfoStore: BaseListInfoStore?
    
    // First key mark line head point Y
    var firstKeyY: CGFloat!
    
    // if a string too long, text must line break. May have two Y!
    var keyYSet: Set<CGFloat> = []
    
    // List link support.
    var prevItem: BaseListItem?
    var nextItem: BaseListItem?
    
    // MARK: - Subclass need override
    
    /// Must override this method
    func listType() -> ListType {
        return ListType.Text
    }
    
    /// Must override this method
    func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) -> BaseListItem {
        return BaseListItem()
    }
    
    /// Usually override this method to perform additional things about destory.
    ///
    /// Must call super in your implementation.
    func destory(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        // Backspace destory this item.
        if byBackspace {
            let lineHeight = ckTextView.font!.lineHeight
            var item = self.nextItem
            var moveY = y
            
            while item != nil {
                item!.firstKeyY = moveY
                
                let newKeyYSet = item!.keyYSet.map({ (value) -> CGFloat in
                    let thatY = moveY
                    moveY += lineHeight
                    return thatY
                })
                // TODO: handle new array to set
                
                item = item!.nextItem
            }
            
        } else {
            // divide list by this Y
            
        }
    }
}
