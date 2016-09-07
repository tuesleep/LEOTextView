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
        
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textView(_:shouldChangeTextInRange:replacementText:))) {
            return nck_delegate!.textView!(textView, shouldChangeTextInRange: range, replacementText: text)
        }
        
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
        
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewDidChangeSelection(_:))) {
            nck_delegate!.textViewDidChangeSelection!(textView)
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
            
            if location < NSString(string: textView.text).length {
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
        }
        
        nck_textStorage.returnKeyDeleteEffectRanges.removeAll()
        
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewDidChange(_:))) {
            nck_delegate!.textViewDidChange!(textView)
        }
    }
    
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewShouldBeginEditing(_:))) {
            return nck_delegate!.textViewShouldBeginEditing!(textView)
        }
        
        return true
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewDidBeginEditing(_:))) {
            nck_delegate!.textViewDidBeginEditing!(textView)
        }
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewShouldEndEditing(_:))) {
            return nck_delegate!.textViewShouldEndEditing!(textView)
        }
        return true
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textViewDidEndEditing(_:))) {
            nck_delegate!.textViewDidEndEditing!(textView)
        }
    }
    
    public func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textView(_:shouldInteractWithTextAttachment:inRange:))) {
            return nck_delegate!.textView!(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange)
        }
        return true
    }
    
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.textView(_:shouldInteractWithURL:inRange:))) {
            return nck_delegate!.textView!(textView, shouldInteractWithURL: URL, inRange: characterRange)
        }
        return true
    }
}
