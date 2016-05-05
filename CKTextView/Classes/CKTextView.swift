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
    
    // Only For CursorType.Numbered
    var currentCursorNumberedListNumber: Int = 0
    
    var willReturnTouch: Bool = false
    var willBackspaceTouch: Bool = false
    
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
        
        self.textContainer.lineBreakMode = .ByCharWrapping
        
        setupNotificationCenterObservers()
        
    }
    
    // MARK: setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    func drawNumberLabelWithY(y: CGFloat, number: Int)
    {
        self.font ?? UIFont.systemFontSize()
        
        let fontSize = self.font!.pointSize
        var width = fontSize + 10
        
        // Woo.. too big
        if number >= 100 {
            let numberCount = "\(number)".characters.count
            width += CGFloat(numberCount - 2) * CGFloat(10)
        }
        
        let height = fontSize + self.textContainer.lineFragmentPadding / 2
        
        let numberBezierPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 8, y: y), size: CGSize(width: width, height: height)))
        let numberLabel = UILabel(frame: numberBezierPath.bounds)
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
    }
    
    // MARK: UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if CKTextUtil.isReturn(text) {
            willReturnTouch = true
        }
        if CKTextUtil.isBackspace(text) {
            willBackspaceTouch = true
        }
        
        
        return true
    }

    public func textViewDidChange(textView: UITextView)
    {
        let cursorLocation = textView.selectedRange.location
        let firstCharInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
        
        // Update cursor point.
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        currentCursorPoint = cursorPoint
        
        print("----------- Status Log -----------")
        print("cursor location: \(cursorLocation)")
        print("text height: \(CKTextUtil.textHeightForTextView(textView))")
        print("cursor point: \(cursorPoint)")
        print("cursor first in line: \(firstCharInLine)")
        print("")
        
        // Keyword input will convert to List style.
        if CKTextUtil.isListKeywordInvokeWithLocation(cursorLocation, type: ListKeywordType.NumberedList, textView: textView)
        {
            let clearRange = Range(start: textView.text.endIndex.advancedBy(-3), end: textView.text.endIndex)
            textView.text.replaceRange(clearRange, with: "")
            
            drawNumberLabelWithY(cursorPoint.y, number: 1)
            
            currentCursorType = CursorType.Numbered
            currentCursorNumberedListNumber = 1
        }
    
        // Handle return operate.
        if willReturnTouch {
            willReturnTouch = false
            
            if currentCursorType == CursorType.Numbered {
                currentCursorNumberedListNumber += 1
                drawNumberLabelWithY(cursorPoint.y, number: currentCursorNumberedListNumber)
            }
        }
        // Handle backspace operate.
        if willBackspaceTouch {
            willBackspaceTouch = false
            
            // Delete list prefix
            if firstCharInLine && currentCursorType != nil
            {
//                if let objs = listPrefixContainerMap[currentCursorPoint!.y]
//                {
//                    objs.0.removeFromSuperview()
//                    
//                    if let index = self.textContainer.exclusionPaths.indexOf(objs.1)
//                    {
//                        self.textContainer.exclusionPaths.removeAtIndex(index)
//                    }
//                    
//                    listPrefixContainerMap.removeValueForKey(currentCursorPoint!.y)
//                }
                
                // TODO: check is set nil ? or not!
                
                currentCursorType = nil
            }
        }
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        print("--------")
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        print("cursor change to point: \(cursorPoint)")
        
        currentCursorPoint = cursorPoint
        
    }
    
    // MARK: Copy & Paste
    
    public override func paste(sender: AnyObject?) {
        print("textview paste invoke. paste content: \(UIPasteboard.generalPasteboard().string)")
    }

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
