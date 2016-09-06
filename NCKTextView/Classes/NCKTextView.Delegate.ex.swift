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
        
        if nck_textStorage.resetFirstLineIndent {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
            typingAttributes = [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: normalFont]
            
        }
    }
}
