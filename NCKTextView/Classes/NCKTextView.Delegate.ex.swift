//
//  NCKTextView.Delegate.ex.swift
//  Pods
//
//  Created by Chanricle King on 06/09/2016.
//
//

import Foundation

var nck_changeText = false

extension NCKTextView: UITextViewDelegate {
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        nck_changeText = true
        return true
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        if nck_changeText {
            nck_changeText = false
        } else {
            // Just judge when text not changed, only section move
            let type = currentParagraphType()
            if type == .Title {
                inputFontMode = .Title
            } else if type == .Body {
                inputFontMode = .Normal
            } else {
                inputFontMode = .Normal
            }
        }
    }
    
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
