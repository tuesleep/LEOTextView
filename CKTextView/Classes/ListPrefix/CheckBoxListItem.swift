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
    var isChecked = false
    
    override func listType() -> ListType {
        return ListType.Checkbox
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
    
    // MARK: - Override
    
    override func createNextItemWithY(y: CGFloat, ckTextView: CKTextView) {
        let nextItem = CheckBoxListItem(keyY: y, ckTextView: ckTextView, listInfoStore: self.listInfoStore)
        handleRelationWithNextItem(nextItem, ckTextView: ckTextView)
    }
    
    override func reDrawGlyph(index: Int, ckTextView: CKTextView) {
        clearGlyph()
        
        setupCheckBoxButton(firstKeyY, ckTextView: ckTextView)
    }
    
    override func clearGlyph() {
        button?.removeFromSuperview()
    }
    
    override func destroy(ckTextView: CKTextView, byBackspace: Bool, withY y: CGFloat) {
        super.destroy(ckTextView, byBackspace: byBackspace, withY: y)
        
        clearGlyph()
    }
    
    // MARK: - Setups
    
    private func setupCheckBoxButton(keyY: CGFloat, ckTextView: CKTextView)
    {
        let lineHeight = ckTextView.font!.lineHeight
        let height = lineHeight
        let width = lineHeight + CGFloat(lineHeight - 8)
        
        button = UIButton(frame: CGRect(x: 8, y: keyY + 1, width: width, height: height))
        button!.addTarget(self, action: #selector(self.checkBoxButtonAction(_:)), forControlEvents: .TouchUpInside)
        button!.titleLabel?.font = UIFont.systemFontOfSize(ckTextView.font!.pointSize + 5)
        button!.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button?.contentHorizontalAlignment = .Center
        
        changeCheckBoxButtonBg()
        
        // Append label to textView.
        ckTextView.addSubview(button!)
    }
    
    // MARK: - Button Action
    
    func checkBoxButtonAction(checkBoxButton: UIButton) {
        isChecked = !isChecked
        changeCheckBoxButtonBg()
    }
    
    // MARK: -
    
    func changeCheckBoxButtonBg() {
        let buttonTitle = isChecked ? "◉" : "◎"
        button!.setTitle(buttonTitle, forState: .Normal)
    }
}
