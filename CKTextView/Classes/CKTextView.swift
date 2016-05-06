//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

enum CursorType {
    case Numbered
}

public class CKTextView: UITextView, UITextViewDelegate, UIActionSheetDelegate {
    // Record current cursor point, to choose operations.
    var currentCursorPoint: CGPoint?
    var currentCursorType: CursorType?
    
    var prevCursorPoint: CGPoint?
    var prevCursorY: CGFloat?
    
    var willReturnTouch: Bool = false
    var willBackspaceTouch: Bool = false
    var willChangeText: Bool = false
    var willDeletedString: String?
    
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
    
    // MARK: setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    func drawNumberLabelWithY(y: CGFloat, number: Int) -> NumberedListItem
    {
        self.font ?? UIFont.systemFontSize()
        
        let lineHeight = self.font!.lineHeight
        var width = lineHeight + 10
        
        // Woo.. too big
        if number >= 100 {
            let numberCount = "\(number)".characters.count
            width += CGFloat(numberCount - 2) * CGFloat(10)
        }
        
        let x: CGFloat = 0
        let lineFragmentPadding = self.textContainer.lineFragmentPadding
        let size = CGSize(width: width, height: lineHeight)
        
        let numberBezierPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: x, y: y), size: size))
        
//        let numberLabel = UILabel(frame: CGRect(origin: CGPoint(x: x, y: y + lineFragmentPadding / 2), size: CGSize(width: width, height: fontSize)))
        let numberLabel = UILabel(frame: numberBezierPath.bounds)
        numberLabel.backgroundColor = UIColor.lightGrayColor()
        numberLabel.text = "\(number)."
        numberLabel.font = font
        
        if number < 10 {
            numberLabel.text = "  \(number)."
        }
        
        // Append label and exclusion bezier path.
        self.addSubview(numberLabel)
        self.textContainer.exclusionPaths.append(numberBezierPath)
        
        let numberedListItem = NumberedListItem(keyY: y, label: numberLabel, bezierPath: numberBezierPath, number: number)
        
        // Save to container
        listPrefixContainerMap[y] = numberedListItem
        
        return numberedListItem
    }
    
    // MARK: Change even
    
    func changeCurrentCursorPointIfNeeded(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
        
        if prevCursorPoint!.y != cursorPoint.y {
            prevCursorY = prevCursorPoint!.y
            
            // Text not change, only normal cursor moving..
            if !willChangeText || willBackspaceTouch {
                currentCursorType = listPrefixContainerMap[cursorPoint.y] == nil ? nil : CursorType.Numbered
                return
            }
            
            // Text changed, something happend.
            // Handle too long string typed.. add moreline bezierPath space fill. and set key to container.
            if !willReturnTouch && !willBackspaceTouch {
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
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if CKTextUtil.isReturn(text) {
            willReturnTouch = true
        }
        if CKTextUtil.isBackspace(text) {
            willBackspaceTouch = true
            
            let cursorLocation = textView.selectedRange.location
            
            if cursorLocation == 0 {
                // If delete first character.
                let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
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
        willChangeText = false
        
        let cursorLocation = textView.selectedRange.location
        
        // Update cursor point.
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
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
            
            drawNumberLabelWithY(cursorPoint.y, number: 1)
            
            currentCursorType = CursorType.Numbered
        }
    
        // Handle return operate.
        if willReturnTouch {
            willReturnTouch = false
            
            if currentCursorType == CursorType.Numbered {
                if CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView) {
                    
                } else {
                    let item = listPrefixContainerMap[prevCursorY!]
                    
                    let newItem = drawNumberLabelWithY(cursorPoint.y, number: item!.number + 1)
                    
                    // Handle prev, next relationships.
                    item?.nextItem = newItem
                    newItem.prevItem = item
                }
            }
        }
        // Handle backspace operate.
        if willBackspaceTouch {
            willBackspaceTouch = false
            
            // Delete list prefix
            guard willDeletedString != nil && willDeletedString!.containsString("\n") else { return }
            guard prevCursorY != nil else { return }
            
            deleteListPrefixWithY(prevCursorY!, cursorPoint: cursorPoint)
            
            willDeletedString = nil
        }
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        changeCurrentCursorPointIfNeeded(cursorPoint)
    }
    
    func deleteListPrefixWithY(y: CGFloat, cursorPoint: CGPoint)
    {
        if let item = listPrefixContainerMap[y] {
        
            item.label.removeFromSuperview()
            
            if let index = self.textContainer.exclusionPaths.indexOf(item.bezierPath)
            {
                self.textContainer.exclusionPaths.removeAtIndex(index)
            }
            
            for (index, value) in item.keyYSet.enumerate() {
                listPrefixContainerMap.removeValueForKey(value)
            }
            
            // reload
            changeCurrentCursorPointIfNeeded(cursorPoint)
        }
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
