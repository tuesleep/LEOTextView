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
            
            guard let currentParagraphStyle = self.textStorage.attribute(NSParagraphStyleAttributeName, atIndex: objectIndex, effectiveRange: nil) as? NSParagraphStyle else {
                return
            }
            
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
        
        guard let nck_textStorage = textStorage as? NCKTextStorage else {
            return
        }
        
        nck_textStorage.returnKeyDeleteEffectRanges.forEach {
            let location = $0.first!.0
            let fontType = $0.first!.1
            
            var font = normalFont
            
            switch fontType {
            case .Normal:
                font = normalFont
                break
            case .Title:
                font = titleFont
                break
            case .Bold:
                font = boldFont
                break
            case .Italic:
                font = italicFont
                break
            }
            
            textStorage.addAttributes([NSFontAttributeName: font], range: NSMakeRange(location, 1))
        }
        
        nck_textStorage.returnKeyDeleteEffectRanges.removeAll()
    }
}
