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
    
    func endYWithLineHeight(lineHeight: CGFloat) -> CGFloat {
        return firstKeyY + CGFloat(keyYSet.count) * lineHeight
    }
    
    // MARK: - Subclass need override
    
    /// Must override this method
    func listType() -> ListType {
        return ListType.Text
    }
    
    /// Must override this method
    func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) -> BaseListItem {
        return BaseListItem()
    }
    
    /// Must override this method
    func reDrawGlyph(ckTextView: CKTextView) {
        
    }
    
    /// Usually override this method to perform additional things about destory.
    ///
    /// Must call super in your implementation.
    func destory(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        // Backspace destory this item.
        if byBackspace {
            // handle first item delete
            var firstItem = self
            
            // delete first item of list, this item's next item become a first item.
            if firstItem.prevItem == nil {
                firstItem.listInfoStore?.clearBezierPath(ckTextView)
                
                if firstItem.nextItem != nil {
                    firstItem.nextItem?.firstKeyY = firstItem.firstKeyY
                    firstItem = firstItem.nextItem!
                    
                    resetAllItemYWithFirstItem(firstItem, ckTextView: ckTextView)
                } else {
                    resetAllItemYWithFirstItem(firstItem, ckTextView: ckTextView)
                }
                
            } else {
                // Link prev item with next item.
                if self.nextItem != nil {
                    self.prevItem?.nextItem = self.nextItem
                }
                
                firstItem = firstItem.prevItem!
                
                while firstItem.prevItem != nil {
                    firstItem = firstItem.prevItem!
                }
                resetAllItemYWithFirstItem(firstItem, ckTextView: ckTextView)
            }
            
        } else {
            // divide list by this Y
            var firstItems: Array<BaseListItem> = []
            
            if self.prevItem != nil {
                self.prevItem?.nextItem = nil
                var firstItem = self.prevItem!
                
                while firstItem.prevItem != nil {
                    firstItem = firstItem.prevItem!
                }
                firstItems.append(firstItem)
            }
            
            if self.nextItem != nil {
                self.nextItem?.prevItem = nil
                var firstItem = self.nextItem!
                
                firstItem.firstKeyY = y
                
                firstItems.append(firstItem)
            }
            
            self.listInfoStore?.clearBezierPath(ckTextView)
            
            for item in firstItems {
                resetAllItemYWithFirstItem(item, ckTextView: ckTextView)
            }
        }
    }
    
    func resetAllItemYWithFirstItem(firstItem: BaseListItem, ckTextView: CKTextView) {
        let lineHeight = ckTextView.font!.lineHeight
        
        firstItem.listInfoStore?.listStartByY = firstItem.firstKeyY
        
        var moveY = firstItem.endYWithLineHeight(lineHeight)
        var item = firstItem.nextItem
        
        if item == nil {
            firstItem.listInfoStore!.listEndByY = firstItem.endYWithLineHeight(lineHeight) - lineHeight
            firstItem.listInfoStore!.fillBezierPath(ckTextView)
            
        } else {
            while item != nil {
                item!.firstKeyY = moveY
                
                let newKeyYArray = item!.keyYSet.map({ (value) -> CGFloat in
                    let thatY = moveY
                    moveY += lineHeight
                    return thatY
                })
                item!.keyYSet = Set(newKeyYArray)
                item!.reDrawGlyph(ckTextView)
                
                moveY = item!.endYWithLineHeight(lineHeight)
                
                // Handle last item.
                if item!.nextItem == nil {
                    // set list end Y
                    item!.listInfoStore!.listEndByY = item!.endYWithLineHeight(lineHeight) - lineHeight
                    item!.listInfoStore!.fillBezierPath(ckTextView)
                }
                
                // Go next
                item = item!.nextItem
            }
        }
    }
    
}
