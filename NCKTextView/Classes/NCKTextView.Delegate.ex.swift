//
//  NCKTextView.Delegate.ex.swift
//  Pods
//
//  Created by Chanricle King on 06/09/2016.
//
//

import Foundation

extension NCKTextView: UITextViewDelegate {
    public func textViewDidChange(textView: UITextView) {
        guard let nck_textStorage = textStorage as? NCKTextStorage else {
            return
        }
        
        let paragraphType = currentParagraphType()
        if paragraphType != .BulletedList && paragraphType != .DashedList && paragraphType != .NumberedList {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
            
            // Set paragraph style
            let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
            self.textStorage.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: paragraphRange)
            
            // Set typing style
            typingAttributes = [NSParagraphStyleAttributeName: paragraphStyle]
        }
    }
}
