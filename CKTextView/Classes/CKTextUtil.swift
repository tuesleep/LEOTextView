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
    
    class func isBackspace(text: String) -> Bool
    {
        if text == "" {
            return true
        } else {
            return false
        }
    }
    
    class func clearTextByRange(range: NSRange, textView: UITextView)
    {
        let clearRange = Range(start: textView.text.startIndex.advancedBy(range.location), end: textView.text.startIndex.advancedBy(range.location + range.length))
        textView.text.replaceRange(clearRange, with: "")
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
    
    class func typeForListKeywordWithLocation(location: Int, textView: UITextView) -> ListType
    {
        let checkArray = [("1. ", 3, ListType.Numbered), ("* ", 2, ListType.Bulleted)]
        
        for (index, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            let keyChars = self.keyCharsWithLocation(location, textView: textView, length: length)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    private class func keyCharsWithLocation(location: Int, textView: UITextView, length: Int) -> String
    {
        guard location >= length && CKTextUtil.isFirstLocationInLineWithLocation(location - length, textView: textView) else { return "" }
        
        let textString = textView.text
        let range: Range = Range(start: textString.startIndex.advancedBy(location - length), end: textString.startIndex.advancedBy(location))
        let keyChars = textView.text.substringWithRange(range)
        
        return keyChars
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
