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
    
    override func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) -> BaseListItem {
        let nextItem = NumberedListItem(keyY: y, number: self.number + 1, ckTextView: ckTextView, listInfoStore: self.listInfoStore)
        self.nextItem = nextItem
        nextItem.prevItem = self
        
        self.listInfoStore!.listEndByY = y
        self.listInfoStore!.fillBezierPath(ckTextView)
        
        return nextItem
    }
    
    override func reDrawGlyph(ckTextView: CKTextView) {
        label?.removeFromSuperview()
        
        setupNumberLabel(firstKeyY, ckTextView: ckTextView)
    }
    
    override func destory(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) -> Set<String> {
        let needClearYSet = super.destory(ckTextView, byBackspace: byBackspace, withY: y)
        
        label?.removeFromSuperview()
        
        return needClearYSet
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
