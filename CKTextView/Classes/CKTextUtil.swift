//
//  CKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

class CKTextUtil: NSObject {
    class func isReturn(replacementText: String!) -> Bool
    {
        if replacementText == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isFirstLocationInLineWithLocation(location: Int, textView: UITextView) -> Bool
    {
        if location == 0 {
            return true
        }
        
        let textString = textView.text
        
        let range: Range = Range(start: textString.startIndex.advancedBy(location - 1), end: textString.startIndex.advancedBy(location))
        let keyChar = textView.text.substringWithRange(range)
        print("keyChar: \(keyChar)")
        
        if keyChar == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func textHeightForTextView(textView: UITextView) -> CGFloat
    {
        let textHeight = textView.layoutManager.usedRectForTextContainer(textView.textContainer).height
        return textHeight
    }
}
