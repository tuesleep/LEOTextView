//
//  BaseListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/9/16.
//
//

import UIKit

enum ListType {
    case Text, Numbered, Bulleted, Checkbox
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
    
    /**
        Handle right relation with next item and self.
     */
    func handleRelationWithNextItem(nextItem: BaseListItem, ckTextView: CKTextView) {
        // Insert to queue.
        if self.nextItem != nil {
            self.nextItem!.prevItem = nextItem
            nextItem.nextItem = self.nextItem
        }
        
        self.nextItem = nextItem
        nextItem.prevItem = self
        
        var firstItem = self;
        while firstItem.prevItem != nil {
            firstItem = firstItem.prevItem!
        }
        
        clearContainerWithAllYSet(ckTextView)
        resetAllItemYWithFirstItem(firstItem, ckTextView: ckTextView)
    }
    
    // MARK: - Subclass need override
    
    /// Must override this method
    func listType() -> ListType {
        return ListType.Text
    }
    
    /// Must override this method
    func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) {
        
    }
    
    /// Must override this method
    func reDrawGlyph(index: Int, ckTextView: CKTextView) {
        
    }
    
    /// Usually override this method to perform additional things about destory.
    ///
    /// Must call super in your implementation.
    /// 
    /// - Returns: A set of y that need to be delete.
    func destroy(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat)
    {
        clearContainerWithAllYSet(ckTextView)
        
        // Backspace destroy this item.
        if byBackspace {
            // handle first item delete
            var firstItem = self
            
            // delete first item of list, this item's next item become a first item.
            if firstItem.prevItem == nil {
                if firstItem.nextItem != nil {
                    firstItem = firstItem.nextItem!
                    // Clear prev item, now it's first item.
                    firstItem.prevItem = nil
                    
                    resetAllItemYWithFirstItem(firstItem, ckTextView: ckTextView)
                } else {
                    // List all item destroy.
                    firstItem.listInfoStore?.clearBezierPath(ckTextView)
                }
                
            } else {
                // Link prev item with next item.
                if self.nextItem != nil {
                    self.prevItem?.nextItem = self.nextItem
                    self.nextItem?.prevItem = self.prevItem
                    
                } else {
                    self.prevItem?.nextItem = nil
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
                firstItems.append(firstItem)
            }
            
            for item in firstItems {
                item.listInfoStore?.clearBezierPath(ckTextView)
                item.listInfoStore = BaseListInfoStore(listStartByY: 0, listEndByY: 0)
                
                resetAllItemYWithFirstItem(item, ckTextView: ckTextView)
            }
            
            if firstItems.count == 0 {
                // Handle last item destroy event.
                self.listInfoStore?.clearBezierPath(ckTextView)
            }
        }
    }
    
    // MARK: -
    
    func allYSet(lineHeight: CGFloat) -> Set<String>
    {
        var needClearYSet = Set<String>()
        
        var firstItem = self;
        while firstItem.prevItem != nil {
            firstItem = firstItem.prevItem!
        }
        
        var item: BaseListItem? = firstItem
        
        while item != nil {
            for (_, keyY) in item!.keyYSet.enumerate() {
                needClearYSet.insert(String(Int(keyY)))
            }
            
            item = item!.nextItem
        }
        
        return needClearYSet
    }
    
    func clearContainerWithAllYSet(ckTextView: CKTextView)
    {
        // Clear List info record.
        ckTextView.removeInfoStoreFromContainerWithY(y: self.listInfoStore!.listStartByY)
        
        var needClearYSet = allYSet(ckTextView.font!.lineHeight)
        
        // Clear all old item Y relations.
        for (_, keyY) in needClearYSet.enumerate() {
            ckTextView.listItemContainerMap.removeValueForKey(keyY)
        }
    }
    
    /**
        Reset all item position in list. Set the right firstKeyY of firstItem before call this method.
     
        - Returns: A set of y that is list type.
     */
    func resetAllItemYWithFirstItem(firstItem: BaseListItem, ckTextView: CKTextView) {
        let lineHeight = ckTextView.font!.lineHeight
        
        firstItem.listInfoStore?.listStartByY = firstItem.firstKeyY
        
        // reset firstItem keyYSets
        let keySetCount = firstItem.keyYSet.count
        var newKeyYSet = Set<CGFloat>()
        for i in 0 ..< keySetCount {
            newKeyYSet.insert(firstItem.firstKeyY + CGFloat(i) * firstItem.firstKeyY)
        }
        firstItem.keyYSet = newKeyYSet
        
        // Save new ListInfoStore to container.
        ckTextView.saveToListInfoStoreContainerY(y: firstItem.listInfoStore!.listStartByY)
        // Save first item first.
        ckTextView.saveToListItemContainerWithItem(firstItem)
        
        var index = 0
        
        firstItem.reDrawGlyph(index, ckTextView: ckTextView)
        index += 1
        
        var moveY = firstItem.endYWithLineHeight(lineHeight)
        var item = firstItem.nextItem
        
        if item == nil {
            firstItem.listInfoStore!.listEndByY = firstItem.endYWithLineHeight(lineHeight) - lineHeight
            firstItem.listInfoStore!.fillBezierPath(ckTextView)
            
        } else {
            while item != nil {
                // sync listInfoStore object.
                item!.listInfoStore = firstItem.listInfoStore
                item!.firstKeyY = moveY
                
                let newKeyYArray = item!.keyYSet.map({ (value) -> CGFloat in
                    let thatY = moveY
                    moveY += lineHeight
                    return thatY
                })
                item!.keyYSet = Set(newKeyYArray)
                
                item!.reDrawGlyph(index, ckTextView: ckTextView)
                index += 1
                
                ckTextView.saveToListItemContainerWithItem(item!)
                
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
