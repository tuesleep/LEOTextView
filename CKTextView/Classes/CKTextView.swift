//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

public class CKTextView: UITextView, UITextViewDelegate, UIActionSheetDelegate {
    // Record current cursor point, to choose operations.
    var currentCursorPoint: CGPoint?
    var currentCursorType: ListType = .Text
    
    var prevCursorPoint: CGPoint?
    
    var willReturnTouch: Bool = false
    var willBackspaceTouch: Bool = false
    var willChangeText: Bool = false
    
    // Save Y and ListItem relationship.
    var listItemContainerMap: Dictionary<String, BaseListItem> = [:]
    
    // Save Y and InfoStore relationship.
    var listInfoStoreContainerMap: Dictionary<String, Int> = [:]
    
    public class func ck_textView(frame: CGRect) -> CKTextView
    {
        let ckTextContainer = CKTextContainer(size: CGSize(width: CGRectGetWidth(frame), height: CGFloat.max))
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(ckTextContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        return CKTextView(frame: frame, textContainer: ckTextContainer)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initialized()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialized()
    }
    
    func initialized()
    {
        self.delegate = self
        
        setupNotificationCenterObservers()
        
    }
    
    // MARK: - Container getter & setter
    
    func saveToListItemContainerWithItem(item: BaseListItem) {
        for (_, keyY) in item.keyYSet.enumerate() {
            listItemContainerMap[String(format: "%.1f", keyY)] = item
        }
    }
    
    func itemFromListItemContainerWithY(y:CGFloat) -> BaseListItem?
    {
        return listItemContainerMap[String(format: "%.1f", y)]
    }
    
    func saveToListInfoStoreContainerY(y keyY: String)
    {
        listInfoStoreContainerMap[keyY] = 0
    }
    
    func removeInfoStoreFromContainerWithY(y keyY: String)
    {
        listInfoStoreContainerMap.removeValueForKey(keyY);
    }
    
    // MARK: - Setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    /**
        Do something about delete list item.
     
        - Returns: return bool value defined is delete first item of list.
     */
    func deleteListPrefixWithY(y: CGFloat, cursorPoint: CGPoint, byBackspace: Bool) -> Bool
    {
        var isDeleteFirstItem = false
        
        if let item = itemFromListItemContainerWithY(y)
        {
            isDeleteFirstItem = item.firstKeyY == item.listInfoStore!.listStartByY
            
            item.destroy(self, byBackspace: byBackspace, withY: y)
            
            // reload
            changeCurrentCursorPointIfNeeded(cursorPoint)
        }
        
        return isDeleteFirstItem
    }
    
    // MARK: - UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        CKTextUtil.checkChangedTextInfo(textView, shouldChangeTextInRange: range, replacementText: text)
        
        
        var isContinue = true
        
        if CKTextUtil.isSpace(text)
        {
            isContinue = handleSpaceEvent(textView)
        }
        else if CKTextUtil.isReturn(text)
        {
            willReturnTouch = true
            isContinue = handleReturnEvent(textView)
        }
        else if CKTextUtil.isBackspace(text)
        {
            willBackspaceTouch = true
            isContinue = handleBackspaceEvent(textView)
            
            if range.location == 0 && range.length == 0 {
                isContinue = false
            }
        }
        
        if isContinue {
            willChangeText = true
        } else {
            willChangeText = false
        }
        
        return isContinue
    }

    public func textViewDidChangeSelection(textView: UITextView) {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        changeCurrentCursorPointIfNeeded(cursorPoint)
        
        willChangeText = false
        willReturnTouch = false
        willBackspaceTouch = false
    }
    
    public func textViewDidChange(textView: UITextView)
    {
        
    }
    
    // MARK: - Event Handler
    
    func handleSpaceEvent(textView: UITextView) -> Bool
    {
        let cursorLocation = textView.selectedRange.location
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
        // Keyword input will convert to List style.
        switch CKTextUtil.typeForListKeywordWithLocation(cursorLocation, textView: textView) {
        case .Numbered:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 2, 2), textView: textView)
            
            let numberedListItem = NumberedListItem(keyY: cursorPoint.y, number: 1, ckTextView: self, listInfoStore: nil)
            
            numberedListItem.listInfoStore?.fillBezierPath(self)
            
            // Save to container
            saveToListItemContainerWithItem(numberedListItem)
            saveToListInfoStoreContainerY(y: numberedListItem.listInfoStore!.listFirstKeyY)
            
            currentCursorType = ListType.Numbered
            
            return false
            
        case .Bulleted:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 1, 1), textView: textView)
            
            let bulletedListItem = BulletedListItem(keyY: cursorPoint.y, ckTextView: self, listInfoStore: nil)
            
            bulletedListItem.listInfoStore?.fillBezierPath(self)
            
            // Save to container
            saveToListItemContainerWithItem(bulletedListItem)
            saveToListInfoStoreContainerY(y: bulletedListItem.listInfoStore!.listFirstKeyY)
            
            currentCursorType = ListType.Bulleted
            
            return false
        case .Checkbox:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 2, 2), textView: textView)
            
            let checkBoxListItem = CheckBoxListItem(keyY: cursorPoint.y, ckTextView: self, listInfoStore: nil)
            
            checkBoxListItem.listInfoStore?.fillBezierPath(self)
            
            saveToListItemContainerWithItem(checkBoxListItem)
            saveToListInfoStoreContainerY(y: checkBoxListItem.listInfoStore!.listFirstKeyY)
            
            currentCursorType = ListType.Checkbox
            
            return false
        case .Text:
            return true
        }
    }
    
    func handleReturnEvent(textView: UITextView) -> Bool
    {
        let cursorLocation = textView.selectedRange.location
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        let lineHeight = textView.font!.lineHeight
        
        let isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
        
        if currentCursorType != ListType.Text
        {
            if isFirstLocationInLine {
                let isEmptyLine = CKTextUtil.isEmptyLine(cursorLocation, textView: textView)
                
                if isEmptyLine {
                    deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: false)
                    currentCursorType = .Text
                    willReturnTouch = false
                    
                    return false
                } else {
                    if let item = itemFromListItemContainerWithY(cursorPoint.y) {
                        item.createNextItemWithY(cursorPoint.y + lineHeight, ckTextView: self)
                    }
                }
                
            } else {
                if let item = itemFromListItemContainerWithY(cursorPoint.y) {
                    item.createNextItemWithY(cursorPoint.y + lineHeight, ckTextView: self)
                }
            }
        }
        
        return true
    }
    
    func handleBackspaceEvent(textView: UITextView) -> Bool
    {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
        if currentCursorType != ListType.Text {
            let cursorLocation = textView.selectedRange.location
            
            let isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
            
            if isFirstLocationInLine {
                // If delete first character.
                let isDeleteFirstItem = deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: true)
                
                if isDeleteFirstItem {
                    // Do not delete prev '\n' char when first item deleting.
                    return false
                }
            }
        }
        
        return true
    }
    
    func handleLineChanged(y: CGFloat, moveValue: CGFloat)
    {
        let infoStores = listInfoStoreContainerMap.filter { (keyY, infoStore) -> Bool in
            if let numberY = NSNumberFormatter().numberFromString(keyY) {
                let floatY = CGFloat(numberY)
                
                if floatY > y {
                    return true
                } else {
                    return false
                }
            }
            
            return true
        }
        
        for (firstKeyY, _) in infoStores {
            guard let item = listItemContainerMap[firstKeyY] else { continue }
            
            item.clearContainerWithAllYSet(self)
            
            item.firstKeyY = item.firstKeyY + moveValue
            
            item.resetAllItemYWithFirstItem(item, ckTextView: self)
        }
        
    }
    
    func changeCurrentCursorPointIfNeeded(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
        
        if prevCursorPoint!.y != cursorPoint.y {
            
            
            // Handle all list that after this y position.
            if willChangeText {
                let moveValue = cursorPoint.y - prevCursorPoint!.y
                handleLineChanged(prevCursorPoint!.y, moveValue: moveValue)
            }
            
            guard !willReturnTouch else { return }
            
            // Text not change, only normal cursor moving.. Or backspace touched.
            if !willChangeText || willBackspaceTouch {
                let item = itemFromListItemContainerWithY(cursorPoint.y)
                
                currentCursorType = item == nil ? ListType.Text : item!.listType()
                
                return
            }
            
            // Text changed, something happend.
            // Handle too long string typed.. add moreline bezierPath space fill. and set key to container.
            if !willBackspaceTouch {
                if let item = itemFromListItemContainerWithY(prevCursorPoint!.y)
                {
                    // key Y of New line add to container.
                    item.keyYSet.insert(cursorPoint.y)
                    saveToListItemContainerWithItem(item)
                    // TODO: change BeizerPathRect, more height
                }
            }
            
            print("cursorY changed to: \(currentCursorPoint?.y), prev cursorY: \(prevCursorPoint!.y)")
        }
    }
    
    // MARK: - Copy & Paste
    
//    public override func paste(sender: AnyObject?) {
//        print("textview paste invoke. paste content: \(UIPasteboard.generalPasteboard().string)")
//    }
    
    // MARK: - KVO
    
    func keyboardWillShow(notification: NSNotification)
    {
        if let userInfo: NSDictionary = notification.userInfo {
            let value = userInfo["UIKeyboardBoundsUserInfoKey"]
            if let rect = value?.CGRectValue() {
                self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: rect.height + 100, right: 0)
            }
        }
    }
}
