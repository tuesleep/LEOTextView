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
        let paragraphType = currentParagraphType()
        if paragraphType != .BulletedList && paragraphType != .DashedList && paragraphType != .NumberedList {
            let objectIndex = NCKTextUtil.objectLineAndIndexWithString(text, location: selectedRange.location).1
            
            if objectIndex >= NSString(string: text).length {
                return
            }
            
            let currentParagraphStyle = self.textStorage.attribute(NSParagraphStyleAttributeName, atIndex: objectIndex, effectiveRange: nil) as! NSParagraphStyle
            
            if currentParagraphStyle.firstLineHeadIndent == 0 {
                return
            }
            
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
