//
//  BulletedListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/11/16.
//
//

import UIKit

class BulletedListItem: BaseListItem {
    var label: UILabel?
    
    override func listType() -> ListType {
        return ListType.Bulleted
    }
    
    required init(keyY: CGFloat, ckTextView: CKTextView, listInfoStore: BaseListInfoStore?)
    {
        super.init()
        
        self.firstKeyY = keyY
        self.keyYSet.insert(keyY)
        
        // create number
        setupBulletLabel(keyY, ckTextView: ckTextView)
        
        if listInfoStore == nil {
            self.listInfoStore = BaseListInfoStore(listStartByY: keyY, listEndByY: keyY)
        } else {
            self.listInfoStore = listInfoStore
            self.listInfoStore!.listEndByY = keyY
        }
    }
    
    // MARK: Override
    
    override func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) -> BaseListItem {
        let nextItem = BulletedListItem(keyY: y, ckTextView: ckTextView, listInfoStore: self.listInfoStore)
        self.nextItem = nextItem
        nextItem.prevItem = self
        
        self.listInfoStore!.listEndByY = y
        self.listInfoStore!.fillBezierPath(ckTextView)
        
        return nextItem
    }
    
    override func reDrawGlyph(ckTextView: CKTextView) {
        label?.removeFromSuperview()
        
        setupBulletLabel(firstKeyY, ckTextView: ckTextView)
    }
    
    override func destory(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        super.destory(ckTextView, byBackspace: byBackspace, withY: y)
        
        label?.removeFromSuperview()
    }
    
    // MARK: setups
    
    private func setupBulletLabel(keyY: CGFloat, ckTextView: CKTextView)
    {
        ckTextView.font ?? UIFont.systemFontSize()
        
        let lineHeight = ckTextView.font!.lineHeight
        
        let height = lineHeight
        var width = lineHeight + 10
        
        label = UILabel(frame: CGRect(x: 8, y: keyY, width: width, height: lineHeight))
        label!.font = ckTextView.font!
        label?.textAlignment = .Center
        label!.text = "●"
        
        // Append label to textView.
        ckTextView.addSubview(label!)
    }
    
}
