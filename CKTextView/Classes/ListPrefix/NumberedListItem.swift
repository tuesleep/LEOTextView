//
//  NumberedListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/5/16.
//
//

import UIKit

class NumberedListItem: BaseListItem {
    
    var label: UILabel?
    var number: Int!
    
    override func listType() -> ListType {
        return ListType.Numbered
    }
    
    required init(keyY: CGFloat, number: Int, ckTextView: CKTextView, listInfoStore: BaseListInfoStore?)
    {
        super.init()
        
        self.firstKeyY = keyY
        self.keyYSet.insert(keyY)

        self.number = number
        
        // create number
        setupNumberLabel(keyY, ckTextView: ckTextView)
        
        if listInfoStore == nil {
            self.listInfoStore = BaseListInfoStore(listStartByY: keyY, listEndByY: keyY)
        } else {
            self.listInfoStore = listInfoStore
            self.listInfoStore!.listEndByY = keyY
        }
    }
    
    // MARK: Override
    
    override func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) {
        let nextItem = NumberedListItem(keyY: y, number: self.number + 1, ckTextView: ckTextView, listInfoStore: self.listInfoStore)
        handleRelationWithNextItem(nextItem, ckTextView: ckTextView)
    }
    
    override func reDrawGlyph(index: Int, ckTextView: CKTextView) {
        clearGlyph()
        
        if index >= 0 {
            number = index + 1
        }
        
        setupNumberLabel(firstKeyY, ckTextView: ckTextView)
    }
    
    override func clearGlyph() {
        label?.removeFromSuperview()
    }
    
    override func destroy(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        let needClearYSet = super.destroy(ckTextView, byBackspace: byBackspace, withY: y)
        
        clearGlyph()
    }
    
    // MARK: setups
    
    private func setupNumberLabel(keyY: CGFloat, ckTextView: CKTextView)
    {
        let lineHeight = ckTextView.font!.lineHeight
        var width = lineHeight + 10
        
        // Woo.. too big
        if number >= 100 {
            let numberCount = "\(number)".characters.count
            width += CGFloat(numberCount - 2) * CGFloat(10)
        }
        
        label = UILabel(frame: CGRect(x: 8, y: keyY, width: width, height: lineHeight))
        label!.text = "\(number)."
        label!.font = ckTextView.font!
        
        if number < 10 {
            label!.text = "  \(number)."
        }
        
        // Append label to textView.
        ckTextView.addSubview(label!)
    }
}
