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
    var listPrefixContainerMap: Dictionary<String, BaseListItem> = [:]
    
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
    
    func saveToListPrefixContainerY(y: CGFloat, item: BaseListItem)
    {
        listPrefixContainerMap[String(y)] = item
    }
    
    func itemFromListPrefixContainerWithY(y:CGFloat) -> BaseListItem?
    {
        return listPrefixContainerMap[String(y)]
    }
    
    // MARK: - Setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    func deleteListPrefixWithY(y: CGFloat, cursorPoint: CGPoint, byBackspace: Bool)
    {
        print("Will delete by Y: \(y)")
        
        if let item = itemFromListPrefixContainerWithY(y)
        {
            let needClearYSet = item.destory(self, byBackspace: byBackspace, withY: y)
            
            print("That unluck y need to be remove: \(needClearYSet)")
            
            // Clear self container.
            for (_, value) in needClearYSet.enumerate() {
                if let item = listPrefixContainerMap[value] {
                    
                }
                
                listPrefixContainerMap.removeValueForKey(value)
            }
            
            // reload
            changeCurrentCursorPointIfNeeded(cursorPoint)
        }
    }
    
    // MARK: - Change even
    
    func saveToPrefixContainerWithItem(item: BaseListItem) {
        for (_, value) in item.keyYSet.enumerate() {
            listPrefixContainerMap[String(value)] = item
        }
    }
    
    // MARK: - UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        willChangeText = true
        
        if CKTextUtil.isSpace(text) {
            return handleSpaceEvent(textView)
        } else if CKTextUtil.isReturn(text) {
            willReturnTouch = true
            return handleReturnEvent(textView)
        } else if CKTextUtil.isBackspace(text) {
            willBackspaceTouch = true
            return handleBackspaceEvent(textView)
        }
        
        return true
    }

    public func textViewDidChangeSelection(textView: UITextView) {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        changeCurrentCursorPointIfNeeded(cursorPoint)
        
        print("Now! Cursor Type is: \(currentCursorType)")
    }
    
    public func textViewDidChange(textView: UITextView)
    {
        willChangeText = false
        willReturnTouch = false
        willBackspaceTouch = false
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
            saveToPrefixContainerWithItem(numberedListItem)
            currentCursorType = ListType.Numbered
            
            return false
            
        case .Bulleted:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 1, 1), textView: textView)
            
            let bulletedListItem = BulletedListItem(keyY: cursorPoint.y, ckTextView: self, listInfoStore: nil)
            
            bulletedListItem.listInfoStore?.fillBezierPath(self)
            
            // Save to container
            saveToPrefixContainerWithItem(bulletedListItem)
            currentCursorType = ListType.Bulleted
            
            return false
        case .Checkbox:
            // TODO: Checkbox need to be create.
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
                deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: false)
                currentCursorType = .Text
                willReturnTouch = false
                
                return false
            } else {
                if let item = itemFromListPrefixContainerWithY(cursorPoint.y) {
                    let nextItem = item.createNextItemWithY(cursorPoint.y + lineHeight, ckTextView: self)
                    saveToPrefixContainerWithItem(nextItem)
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
                deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: true)
            }
        }
        
        return true
    }
    
    func changeCurrentCursorPointIfNeeded(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
        
        if prevCursorPoint!.y != cursorPoint.y {
            guard !willReturnTouch else { return }
            
            // Text not change, only normal cursor moving.. Or backspace touched.
            if !willChangeText || willBackspaceTouch {
                let item = itemFromListPrefixContainerWithY(cursorPoint.y)
                
                currentCursorType = item == nil ? ListType.Text : item!.listType()
                
                return
            }
            
            // Text changed, something happend.
            // Handle too long string typed.. add moreline bezierPath space fill. and set key to container.
            if !willBackspaceTouch {
                if let item = itemFromListPrefixContainerWithY(prevCursorPoint!.y)
                {
                    // key Y of New line add to container.
                    item.keyYSet.insert(cursorPoint.y)
                    saveToPrefixContainerWithItem(item)
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
