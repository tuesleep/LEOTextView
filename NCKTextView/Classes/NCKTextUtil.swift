//
//  NCKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

class NCKTextUtil: NSObject {
    static let markdownUnorderedListRegularExpression = try! NSRegularExpression(pattern: "^[-*] .", options: .CaseInsensitive)
    static let markdownOrderedListRegularExpression = try! NSRegularExpression(pattern: "^\\d*\\. .", options: .CaseInsensitive)
    static let markdownOrderedListAfterItemsRegularExpression = try! NSRegularExpression(pattern: "\\n\\d*\\. ", options: .CaseInsensitive)
    
    class func isReturn(text: String) -> Bool {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }
}