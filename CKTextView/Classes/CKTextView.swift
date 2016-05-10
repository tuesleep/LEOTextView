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
    var currentCursorType: ListType = .None
    
    var prevCursorPoint: CGPoint?
    var prevCursorY: CGFloat?
    
    var willReturnTouch: Bool = false
    var willBackspaceTouch: Bool = false
    var willChangeText: Bool = false
    var willDeletedString: String?
    
    var isFirstLocationInLine: Bool = false
    
    var listPrefixContainerMap: Dictionary<CGFloat, NumberedListItem> = [:]

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
    
    // MARK: Setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    // MARK: Drawing

    func drawNumberLabelWithY(y: CGFloat, number: Int, prevItem: NumberedListItem?) -> NumberedListItem
    {
        let numberedListItem = NumberedListItem(keyY: y, number: number, ckTextView: self, listInfoStore: prevItem?.listInfoStore)
        
        // Save to container
        listPrefixContainerMap[y] = numberedListItem
        
        return numberedListItem
    }
    
    func deleteListPrefixWithY(y: CGFloat, cursorPoint: CGPoint)
    {
        print("Will delete by Y: \(y)")
        
        if let item = listPrefixContainerMap[y]
        {
            item.destory(self)
            
            // Clear self container.
            for (index, value) in item.keyYSet.enumerate() {
                listPrefixContainerMap.removeValueForKey(value)
            }
            
            // reload
            changeCurrentCursorPointIfNeeded(cursorPoint)
        }
    }
    
    // MARK: Change even
    
    func changeCurrentCursorPointIfNeeded(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
        
        if prevCursorPoint!.y != cursorPoint.y {
            prevCursorY = prevCursorPoint!.y
            
            guard !willReturnTouch else { return }
            
            // Text not change, only normal cursor moving.. Or backspace touched.
            if !willChangeText || willBackspaceTouch {
                currentCursorType = listPrefixContainerMap[cursorPoint.y] == nil ? ListType.Text : ListType.Numbered
                
                return
            }
            
            // Text changed, something happend.
            // Handle too long string typed.. add moreline bezierPath space fill. and set key to container.
            if !willBackspaceTouch {
                if let item = listPrefixContainerMap[prevCursorY!]
                {
                    // key Y of New line add to container.
                    item.keyYSet.insert(cursorPoint.y)
                    listPrefixContainerMap[cursorPoint.y] = item
                    
                    // TODO: change BeizerPathRect, more height
                }
            }
            
            print("cursorY changed to: \(currentCursorPoint?.y), prev cursorY: \(prevCursorY)")
        }
    }
    
    // MARK: UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        let cursorLocation = textView.selectedRange.location
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
        isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
        
        if CKTextUtil.isReturn(text) {
            willReturnTouch = true
            
            isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
        
            if (currentCursorType == ListType.Numbered) && isFirstLocationInLine
            {
                deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint)
                currentCursorType = .Text
                willReturnTouch = false
                
                return false
            }
        }
        if CKTextUtil.isBackspace(text) {
            willBackspaceTouch = true
            
            let cursorLocation = textView.selectedRange.location
            
            if cursorLocation == 0 {
                // If delete first character.
                deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint)
                
            } else {
                let deleteRange = Range(start: textView.text.startIndex.advancedBy(range.location), end: textView.text.startIndex.advancedBy(range.location + range.length))
                willDeletedString = textView.text.substringWithRange(deleteRange)
            }
        }
        
        willChangeText = true
        
        return true
    }

    public func textViewDidChange(textView: UITextView)
    {
        print(currentCursorType)
        
        guard currentCursorPoint != nil else { return }
        
        let cursorLocation = textView.selectedRange.location
        
//        print("----------- Status Log -----------")
//        print("cursor location: \(cursorLocation)")
//        print("text height: \(CKTextUtil.textHeightForTextView(textView))")
//        print("cursor point: \(cursorPoint)")
//        print("")
        
        // Keyword input will convert to List style.
        if CKTextUtil.isListKeywordInvokeWithLocation(cursorLocation, type: ListKeywordType.NumberedList, textView: textView)
        {
            let clearRange = Range(start: textView.text.endIndex.advancedBy(-3), end: textView.text.endIndex)
            textView.text.replaceRange(clearRange, with: "")
            
            drawNumberLabelWithY(currentCursorPoint!.y, number: 1, prevItem: nil)
            
            currentCursorType = ListType.Numbered
        }
    
        // Handle return operate.
        if willReturnTouch {
            if currentCursorType == ListType.Numbered {
                let item = listPrefixContainerMap[prevCursorY!]
                // Draw new item.
                let newItem = drawNumberLabelWithY(currentCursorPoint!.y, number: item!.number + 1, prevItem: item)
                
                // Handle prev, next relationships.
                item?.nextItem = newItem
                newItem.prevItem = item
            }
            
            willReturnTouch = false
        }
        // Handle backspace operate.
        if willBackspaceTouch {
            // Delete list prefix
            guard willDeletedString != nil && willDeletedString!.containsString("\n") else { return }
            guard prevCursorY != nil else { return }
            
            deleteListPrefixWithY(prevCursorY!, cursorPoint: currentCursorPoint!)
            
            willDeletedString = nil
            willBackspaceTouch = false
        }
        
        willChangeText = false
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        changeCurrentCursorPointIfNeeded(cursorPoint)
    }
    
    // MARK: Copy & Paste
    
//    public override func paste(sender: AnyObject?) {
//        print("textview paste invoke. paste content: \(UIPasteboard.generalPasteboard().string)")
//    }

    // MARK: BarButtonItem action
    
    func listButtonAction(sender: UIBarButtonItem)
    {
        print("listButtonAction")
    }
    
    // MARK: KVO
    
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
