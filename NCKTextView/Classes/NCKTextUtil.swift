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
    
    class func isBackspace(text: String) -> Bool {
        if text == "" {
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
        let ns_string = NSString(string: string)
        
        var objectIndex: Int = 0
        var objectLine = ns_string.substringToIndex(location)

        let textSplits = objectLine.componentsSeparatedByString("\n")
        if textSplits.count > 0 {
            let currentObjectLine = textSplits[textSplits.count - 1]
            
            objectIndex = NSString(string: objectLine).length - NSString(string: currentObjectLine).length
            objectLine = currentObjectLine
        }
        
        return (objectLine, objectIndex)
    }
    
    class func objectLineWithString(string: String, location: Int) -> String {
        return objectLineAndIndexWithString(string, location: location).0
    }
    
    class func lineEndIndexWithString(string: String, location: Int) -> Int {
        let remainText: NSString = NSString(string: string).substringFromIndex(location)
        var nextLineBreakLocation = remainText.rangeOfString("\n").location
        nextLineBreakLocation = (nextLineBreakLocation == NSNotFound) ? NSString(string: string).length : nextLineBreakLocation + location
        
        return nextLineBreakLocation
    }
    
    class func paragraphRangeOfString(string: String, location: Int) -> NSRange {
        let startLocation = objectLineAndIndexWithString(string, location: location).1
        let endLocation = lineEndIndexWithString(string, location: location)
        
        return NSMakeRange(startLocation, endLocation - startLocation)
    }
    
    class func currentParagraphStringOfString(string: String, location: Int) -> String {
        return NSString(string: string).substringWithRange(paragraphRangeOfString(string, location: location))
    }
    
    /**
     Just return ListTypes.
     */
    class func paragraphTypeWithObjectLine(objectLine: String) -> NCKInputParagraphType {
        let objectLineRange = NSMakeRange(0, NSString(string: objectLine).length)
        
        let unorderedListMatches = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
        if unorderedListMatches.count > 0 {
            let firstChar = NSString(string: objectLine).substringToIndex(1)
            if firstChar == "-" {
                return .DashedList
            } else {
                return .BulletedList
            }
        }
        
        let orderedListMatches = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
        if orderedListMatches.count > 0 {
            return .NumberedList
        }
        
        return .Body
    }
    
    class func isBoldFont(font: UIFont, boldFontName: String) -> Bool {
        if font.fontName == boldFontName {
            return true
        }
        
        let keywords = ["bold", "medium", "PingFangSC-Regular"]
        
        // At chinese language: PingFangSC-Light is normal, PingFangSC-Regular is bold
        
        return isSpecialFont(font, keywords: keywords)
    }
    
    class func isItalicFont(font: UIFont, italicFontName: String) -> Bool {
        if font.fontName == italicFontName {
            return true
        }
        
        let keywords = ["italic"]
        
        return isSpecialFont(font, keywords: keywords)
    }
    
    class func isSpecialFont(font: UIFont, keywords: [String]) -> Bool {
        let fontName = NSString(string: font.fontName)
        
        for keyword in keywords {
            if fontName.rangeOfString(keyword, options: .CaseInsensitiveSearch).location != NSNotFound {
                return true
            }
        }
        
        return false
    }
    
    class func keyboardWindow() -> UIWindow? {
        var keyboardWin: UIWindow?
        
        UIApplication.sharedApplication().windows.forEach {
            if String($0.dynamicType) == "UITextEffectsWindow" {
                keyboardWin = $0
                return
            }
        }
        
        return keyboardWin
    }
    
}