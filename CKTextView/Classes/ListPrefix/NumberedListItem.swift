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
            setupListInfoStore(keyY, ckTextView: ckTextView)
        } else {
            self.listInfoStore = listInfoStore
            self.listInfoStore!.listEndByY = keyY
        }
        
        // First fill or fill after change endY.
        self.listInfoStore?.fillBezierPath(ckTextView)
    }
    
    // MARK: Override
    
    override func destory(ckTextView: CKTextView, byBackspace: Bool) {
        super.destory(ckTextView, byBackspace: byBackspace)
        
        label?.removeFromSuperview()
    }
    
    // TODO: Override link and unlink method.
    override func unLinkPrevItem() {
        <#code#>
    }
    
    // MARK: setups
    
    private func setupNumberLabel(keyY: CGFloat, ckTextView: CKTextView)
    {
        ckTextView.font ?? UIFont.systemFontSize()
        
        let lineHeight = ckTextView.font!.lineHeight
        
        let height = lineHeight
        var width = lineHeight + 10
        
        // Woo.. too big
        if number >= 100 {
            let numberCount = "\(number)".characters.count
            width += CGFloat(numberCount - 2) * CGFloat(10)
        }
        
        let numberBezierPath = UIBezierPath(rect: CGRect(x: 8, y: keyY, width: width, height: height))
        
        label = UILabel(frame: CGRect(origin: numberBezierPath.bounds.origin, size: CGSize(width: width, height: lineHeight)))
        label!.text = "\(number)."
        label!.font = ckTextView.font!
        
        if number < 10 {
            label!.text = "  \(number)."
        }
        
        // Append label to textView.
        ckTextView.addSubview(label!)
    }
    
    private func setupListInfoStore(keyY: CGFloat, ckTextView: CKTextView) {
        listInfoStore = BaseListInfoStore(listStartByY: keyY, listEndByY: keyY)
    }
}
