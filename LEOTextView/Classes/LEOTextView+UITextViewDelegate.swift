//
//  LEOTextView+UITextViewDelegate.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

var nck_changeText = false

extension LEOTextView: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        nck_changeText = true

        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textView(_:shouldChangeTextIn:replacementText:))) {
            return nck_delegate!.textView!(textView, shouldChangeTextIn: range, replacementText: text)
        }

        return true
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        if nck_changeText {
            nck_changeText = false
        } else {
            // Just judge when text not changed, only section move
            let type = currentParagraphType()
            if type == .title {
                inputFontMode = .title
            } else if type == .body {
                inputFontMode = .normal
            } else {
                inputFontMode = .normal
            }
        }

        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewDidChangeSelection(_:))) {
            nck_delegate!.textViewDidChangeSelection!(textView)
        }
    }

    public func textViewDidChange(_ textView: UITextView) {
        let paragraphType = currentParagraphType()

        let objectIndex = LEOTextUtil.objectLineAndIndexWithString(text, location: selectedRange.location).1

        if objectIndex >= text.length() || objectIndex < 0 {
            return
        }

        guard let currentParagraphStyle = nck_textStorage.safeAttribute(NSAttributedString.Key.paragraphStyle.rawValue, atIndex: objectIndex, effectiveRange: nil, defaultValue: nil) as? NSParagraphStyle else {
            return
        }

        var paragraphStyle: NSMutableParagraphStyle? = nil

        if paragraphType == .body {
            if currentParagraphStyle.firstLineHeadIndent == 0 {
                return
            }

            paragraphStyle = mutableParargraphWithDefaultSetting()
            paragraphStyle!.headIndent = 0
            paragraphStyle!.firstLineHeadIndent = 0

        } else if paragraphType == .bulletedList || paragraphType == .dashedList || paragraphType == .numberedList {
            if currentParagraphStyle.firstLineHeadIndent != 0 {
                return
            }

            let objectLineAndIndex = LEOTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
            let listPrefixString: NSString = NSString(string: objectLineAndIndex.0.components(separatedBy: " ")[0]).appending(" ") as NSString

            paragraphStyle = mutableParargraphWithDefaultSetting()
            paragraphStyle!.headIndent = normalFont.lineHeight + listPrefixString.size(withAttributes: [NSAttributedString.Key.font: normalFont]).width
            paragraphStyle!.firstLineHeadIndent = normalFont.lineHeight
        }

        if paragraphStyle != nil {
            var defaultAttributes = defaultAttributesForLoad
            defaultAttributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle

            // Set paragraph style
            let paragraphRange = LEOTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
            self.textStorage.addAttributes(defaultAttributes, range: paragraphRange)

            // Set typing style
            var attributes = [String: AnyObject]()
            for key in defaultAttributes.keys {
                attributes[key.rawValue] = defaultAttributes[key]
            }
            typingAttributes = convertToNSAttributedStringKeyDictionary(attributes)
        }

        nck_textStorage.returnKeyDeleteEffectRanges.forEach {
            let location = $0.first!.0
            let fontType = $0.first!.1

            if location < textView.text.length() {
                var font = normalFont

                switch fontType {
                case .normal:
                    font = normalFont
                    break
                case .title:
                    font = titleFont
                    break
                case .bold:
                    font = boldFont
                    break
                case .italic:
                    font = italicFont
                    break
                }

                textStorage.addAttributes([NSAttributedString.Key.font: font], range: NSMakeRange(location, 1))
            }
        }

        nck_textStorage.returnKeyDeleteEffectRanges.removeAll()

        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewDidChange(_:))) {
            nck_delegate!.textViewDidChange!(textView)
        }
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewShouldBeginEditing(_:))) {
            return nck_delegate!.textViewShouldBeginEditing!(textView)
        }

        return true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewDidBeginEditing(_:))) {
            nck_delegate!.textViewDidBeginEditing!(textView)
        }
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewShouldEndEditing(_:))) {
            return nck_delegate!.textViewShouldEndEditing!(textView)
        }
        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textViewDidEndEditing(_:))) {
            nck_delegate!.textViewDidEndEditing!(textView)
        }
    }

    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textView(_:shouldInteractWith:in:) as (UITextView, NSTextAttachment, NSRange) -> Bool) as Selector?) {
            return nck_delegate!.textView!(textView, shouldInteractWith: textAttachment, in: characterRange)
        }
        return true
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.textView(_:shouldInteractWith:in:) as (UITextView, URL, NSRange) -> Bool) as Selector?) {
            return nck_delegate!.textView!(textView, shouldInteractWith: URL, in: characterRange)
        }
        return true
    }

}

extension LEOTextView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidScroll(_:))) {
            nck_delegate!.scrollViewDidScroll!(scrollView)
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewWillBeginDragging(_:))) {
            nck_delegate!.scrollViewWillBeginDragging!(scrollView)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewWillEndDragging(_:withVelocity:targetContentOffset:))) {
            nck_delegate!.scrollViewWillEndDragging!(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidEndDragging(_:willDecelerate:))) {
            nck_delegate!.scrollViewDidEndDragging!(scrollView, willDecelerate: decelerate)
        }
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewShouldScrollToTop(_:))) {
            return nck_delegate!.scrollViewShouldScrollToTop!(scrollView)
        }

        return true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidScrollToTop(_:))) {
            nck_delegate!.scrollViewDidScrollToTop!(scrollView)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewWillBeginDecelerating(_:))) {
            nck_delegate!.scrollViewWillBeginDecelerating!(scrollView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidEndDecelerating(_:))) {
            nck_delegate!.scrollViewDidEndDecelerating!(scrollView)
        }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.viewForZooming(in:))) {
            return nck_delegate!.viewForZooming!(in: scrollView)
        }

        return nil
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewWillBeginZooming(_:with:))) {
            nck_delegate!.scrollViewWillBeginZooming!(scrollView, with: view)
        }
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidEndZooming(_:with:atScale:))) {
            nck_delegate!.scrollViewDidEndZooming!(scrollView, with: view, atScale: scale)
        }
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidZoom(_:))) {
            nck_delegate!.scrollViewDidZoom!(scrollView)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if nck_delegate != nil && nck_delegate!.responds(to: #selector(self.scrollViewDidEndScrollingAnimation(_:))) {
            nck_delegate!.scrollViewDidEndScrollingAnimation!(scrollView)
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
