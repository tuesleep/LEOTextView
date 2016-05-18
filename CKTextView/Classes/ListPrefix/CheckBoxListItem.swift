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
    
    // MARK: - Override
    
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
    
    // MARK: - Setups
    
    private func setupCheckBoxButton(keyY: CGFloat, ckTextView: CKTextView)
    {
        let lineHeight = ckTextView.font!.lineHeight
        let distance = lineHeight
        
        button = UIButton(frame: CGRect(x: 12, y: keyY + 3, width: distance, height: distance))
        button!.contentEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
        button!.addTarget(self, action: #selector(self.checkBoxButtonAction(_:)), forControlEvents: .TouchUpInside)
        
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
        let name = isChecked ? "icon-checkbox-checked" : "icon-checkbox-normal"
        
        let bundle = NSBundle(forClass: CheckBoxListItem.self)
        let url = bundle.URLForResource("CKTextView", withExtension: "bundle", subdirectory: "", localization: "")
        let selfBundle = NSBundle(URL: url!)
        
        let backgroundImage = UIImage(named: name, inBundle: selfBundle, compatibleWithTraitCollection: nil)
 
        button!.setBackgroundImage(backgroundImage, forState: .Normal)
    }
}
