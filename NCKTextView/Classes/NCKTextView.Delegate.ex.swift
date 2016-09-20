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
        
        let objectIndex = NCKTextUtil.objectLineAndIndexWithString(text, location: selectedRange.location).1
        
        if objectIndex >= text.length() || objectIndex < 0 {
            return
        }
        
        guard let currentParagraphStyle = nck_textStorage.safeAttribute(NSParagraphStyleAttributeName, atIndex: objectIndex, effectiveRange: nil, defaultValue: nil) as? NSParagraphStyle else {
            return
        }
        
        var paragraphStyle: NSMutableParagraphStyle? = nil
        
        if paragraphType == .Body {
            if currentParagraphStyle.firstLineHeadIndent == 0 {
                return
            }
            
            paragraphStyle = mutableParargraphWithDefaultSetting()
            paragraphStyle!.headIndent = 0
            paragraphStyle!.firstLineHeadIndent = 0
            
        } else if paragraphType == .BulletedList || paragraphType == .DashedList || paragraphType == .NumberedList {
            if currentParagraphStyle.firstLineHeadIndent != 0 {
                return
            }
            
            let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
            let listPrefixString: NSString = NSString(string: objectLineAndIndex.0.componentsSeparatedByString(" ")[0]).stringByAppendingString(" ")
            
            paragraphStyle = mutableParargraphWithDefaultSetting()
            paragraphStyle!.headIndent = normalFont.lineHeight + listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width
            paragraphStyle!.firstLineHeadIndent = normalFont.lineHeight
        }
        
        if paragraphStyle != nil {
            var defaultAttributes = defaultAttributesForLoad
            defaultAttributes[NSParagraphStyleAttributeName] = paragraphStyle
            
            // Set paragraph style
            let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
            self.textStorage.addAttributes(defaultAttributes, range: paragraphRange)
            
            // Set typing style
            typingAttributes = defaultAttributes
        }
        
        nck_textStorage.returnKeyDeleteEffectRanges.forEach {
            let location = $0.first!.0
            let fontType = $0.first!.1
            
            if location < textView.text.length() {
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
        
        let objectLine = NCKTextUtil.objectLineAndIndexWithString(textView.text, location: textView.selectedRange.location)
        
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

extension NCKTextView: UIScrollViewDelegate {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidScroll(_:))) {
            nck_delegate!.scrollViewDidScroll!(scrollView)
        }
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewWillBeginDragging(_:))) {
            nck_delegate!.scrollViewWillBeginDragging!(scrollView)
        }
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewWillEndDragging(_:withVelocity:targetContentOffset:))) {
            nck_delegate!.scrollViewWillEndDragging!(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidEndDragging(_:willDecelerate:))) {
            nck_delegate!.scrollViewDidEndDragging!(scrollView, willDecelerate: decelerate)
        }
    }
    
    public func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewShouldScrollToTop(_:))) {
            return nck_delegate!.scrollViewShouldScrollToTop!(scrollView)
        }
        
        return true
    }
    
    public func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidScrollToTop(_:))) {
            nck_delegate!.scrollViewDidScrollToTop!(scrollView)
        }
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewWillBeginDecelerating(_:))) {
            nck_delegate!.scrollViewWillBeginDecelerating!(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidEndDecelerating(_:))) {
            nck_delegate!.scrollViewDidEndDecelerating!(scrollView)
        }
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.viewForZoomingInScrollView(_:))) {
            return nck_delegate!.viewForZoomingInScrollView!(scrollView)
        }
        
        return nil
    }
    
    public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewWillBeginZooming(_:withView:))) {
            nck_delegate!.scrollViewWillBeginZooming!(scrollView, withView: view)
        }
    }
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidEndZooming(_:withView:atScale:))) {
            nck_delegate!.scrollViewDidEndZooming!(scrollView, withView: view, atScale: scale)
        }
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidZoom(_:))) {
            nck_delegate!.scrollViewDidZoom!(scrollView)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.respondsToSelector(#selector(self.scrollViewDidEndScrollingAnimation(_:))) {
            nck_delegate!.scrollViewDidEndScrollingAnimation!(scrollView)
        }
    }
    
}
