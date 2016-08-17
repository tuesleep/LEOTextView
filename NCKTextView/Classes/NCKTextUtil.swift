//
//  NCKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

class NCKTextUtil: NSObject {
    static let markdownUnorderedListRegularExpression = try! NSRegularExpression(pattern: "^[-*•] ", options: .CaseInsensitive)
    static let markdownOrderedListRegularExpression = try! NSRegularExpression(pattern: "^\\d*\\. ", options: .CaseInsensitive)
    static let markdownOrderedListAfterItemsRegularExpression = try! NSRegularExpression(pattern: "\\n\\d*\\. ", options: .CaseInsensitive)
    
    class func isReturn(text: String) -> Bool {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isSelectedTextWithTextView(textView: UITextView) -> Bool {
        let length = textView.selectedRange.length
        return length > 0
    }
    
    class func objectLineAndIndexWithString(string: String, location: Int) -> (String, Int) {
        var objectIndex: Int = 0
        var objectLine = string.substringToIndex(string.startIndex.advancedBy(location))
        
        let textSplits = objectLine.componentsSeparatedByString("\n")
        if textSplits.count > 0 {
            var currentObjectLine = textSplits[textSplits.count - 1]
            
            objectIndex = NSString(string: objectLine).length - NSString(string: currentObjectLine).length
            objectLine = currentObjectLine
        }
        
        return (objectLine, objectIndex)
    }
}