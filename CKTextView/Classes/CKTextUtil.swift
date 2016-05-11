//
//  CKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

enum ListKeywordType {
    case NumberedList
}

class CKTextUtil: NSObject {
    class func isReturn(text: String) -> Bool
    {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isBackspace(text: String) -> Bool {
        if text == "" {
            return true
        } else {
            return false
        }
    }
    
    class func isFirstLocationInLineWithLocation(location: Int, textView: UITextView) -> Bool
    {
        if location <= 0 {
            return true
        }
        
        let textString = textView.text
        
        let range: Range = Range(start: textString.startIndex.advancedBy(location - 1), end: textString.startIndex.advancedBy(location))
        let keyChar = textView.text.substringWithRange(range)
        
        if keyChar == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isListKeywordInvokeWithLocation(location: Int, type: ListKeywordType, textView: UITextView) -> Bool
    {
        let textString = textView.text
        
        switch type {
        case .NumberedList:
            if location >= 3 && CKTextUtil.isFirstLocationInLineWithLocation(location - 3, textView: textView) {
                let range: Range = Range(start: textString.startIndex.advancedBy(location - 3), end: textString.startIndex.advancedBy(location))
                let keyChar = textView.text.substringWithRange(range)
                
                if keyChar == "1. " {
                    return true
                }
            }
            
            break
        }
        
        return false
    }
    
    class func textHeightForTextView(textView: UITextView) -> CGFloat
    {
        let textHeight = textView.layoutManager.usedRectForTextContainer(textView.textContainer).height
        return textHeight
    }
    
    class func cursorPointInTextView(textView: UITextView) -> CGPoint
    {
        return textView.caretRectForPosition(textView.selectedTextRange!.start).origin
        
    }
    
    
    
}
