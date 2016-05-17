//
//  CheckBoxListItem.swift
//  Pods
//
//  Created by Chanricle King on 5/16/16.
//
//

import UIKit

class CheckBoxListItem: BaseListItem {
    var button: UIButton?
    
    override func listType() -> ListType {
        return ListType.Bulleted
    }
    
    required init(keyY: CGFloat, ckTextView: CKTextView, listInfoStore: BaseListInfoStore?)
    {
        super.init()
        
        self.firstKeyY = keyY
        self.keyYSet.insert(keyY)
        
        // create number
        setupCheckBoxButton(keyY, ckTextView: ckTextView)
        
        if listInfoStore == nil {
            self.listInfoStore = BaseListInfoStore(listStartByY: keyY, listEndByY: keyY)
        } else {
            self.listInfoStore = listInfoStore
            self.listInfoStore!.listEndByY = keyY
        }
    }
    
    // MARK: Override
    
    override func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) {
        let nextItem = CheckBoxListItem(keyY: y, ckTextView: ckTextView, listInfoStore: self.listInfoStore)
        handleRelationWithNextItem(nextItem, ckTextView: ckTextView)
    }
    
    override func reDrawGlyph(index: Int, ckTextView: CKTextView) {
        button?.removeFromSuperview()
        
        setupCheckBoxButton(firstKeyY, ckTextView: ckTextView)
    }
    
    override func destroy(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        super.destroy(ckTextView, byBackspace: byBackspace, withY: y)
        
        button?.removeFromSuperview()
    }
    
    // MARK: setups
    
    private func setupCheckBoxButton(keyY: CGFloat, ckTextView: CKTextView)
    {
        let lineHeight = ckTextView.font!.lineHeight
        
        button = UIButton(frame: CGRect(x: 8, y: keyY, width: lineHeight, height: lineHeight))
        button!.setBackgroundImage(UIImage(named: "icon-checkbox-normal"), forState: .Normal)
        button!.setImage(UIImage(named: "icon-checkbox-normal"), forState: .Normal)
        
        // Append label to textView.
        ckTextView.addSubview(button!)
    }
}
