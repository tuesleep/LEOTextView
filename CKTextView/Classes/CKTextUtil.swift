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
    
    class func textHeightForTextView(textView: UITextView) -> CGFloat
    {
        let textHeight = textView.layoutManager.usedRectForTextContainer(textView.textContainer).height
        return textHeight
    }
}
