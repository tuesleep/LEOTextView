//
//  NSMutableAttributedString.Safe.ex.swift
//  Pods
//
//  Created by Chanricle King on 08/09/2016.
//
//

import Foundation

extension NSMutableAttributedString {
    // MARK: - Safe methods
    
    func safeReplaceCharactersInRange(range: NSRange, withString str: String) {
        if isSafeRange(range) {
            replaceCharactersInRange(range, withString: str)
        }
    }
    
    func safeReplaceCharactersInRange(range: NSRange, withAttributedString attrStr: NSAttributedString) {
        if isSafeRange(range) {
            replaceCharactersInRange(range, withAttributedString: attrStr)
        }
    }
    
    func safeAddAttributes(attrs: [String : AnyObject], range: NSRange) {
        if isSafeRange(range) {
            addAttributes(attrs, range: range)
        }
    }
}

extension NSAttributedString {
    func safeAttribute(attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer, defaultValue: AnyObject?) -> AnyObject? {
        var attributeValue: AnyObject? = nil
        if location < NSString(string: string).length {
            attributeValue = attribute(attrName, atIndex: location, effectiveRange: range)
        }
        
        return attributeValue == nil ? defaultValue : attributeValue
    }
    
    func isSafeRange(range: NSRange) -> Bool {
        let maxLength = range.location + range.length
        if maxLength <= NSString(string: string).length {
            return true
        } else {
            return false
        }
    }
}
