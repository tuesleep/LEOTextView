//
//  NCKTextStorage.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

class NCKTextStorage: NSTextStorage {
    var textView: UITextView!

    var currentString: NSMutableAttributedString = NSMutableAttributedString()
    var attributes: Dictionary<String, AnyObject> = [:]
    
    // MARK: - Must override
    override var string: String {
        return currentString.string
    }
    
    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return currentString.attributesAtIndex(location, effectiveRange: range)
    }
    
    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        var listItemFillText: String = ""
        
        // Unordered and Ordered list auto-complete support
        if NCKTextUtil.isReturn(str) {
            print("woo! return key touch!")
            
            var objectLine = self.string.substringToIndex(self.string.startIndex.advancedBy(range.location))
            let textSplits = objectLine.componentsSeparatedByString("\n")
            if textSplits.count > 0 {
                objectLine = textSplits[textSplits.count - 1]
            }
            
            let objectLineRange = NSRange(location: 0, length: objectLine.characters.count)
            
            // Check matches.
            let unorderedListMatches = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
            let orderedListMatches = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
            
            if unorderedListMatches.count > 0 {
                print("it's a continue item of unordered list")
                
                var listPrefixItem = objectLine.componentsSeparatedByString(" ")[0]
                listItemFillText = "\(listPrefixItem) "
            }
            
            if orderedListMatches.count > 0 {
                print("it's a continue item of ordered list")
                
                var number = Int(objectLine.componentsSeparatedByString(".")[0])
                number! += 1
                listItemFillText = "\(number!). "
            }
        }
        
        beginEditing()
        currentString.replaceCharactersInRange(range, withString: str + listItemFillText)
        edited(.EditedCharacters, range: NSRange(location: range.location, length: range.length), changeInLength: (str.characters.count + listItemFillText.characters.count) - range.length)
        endEditing()
        
        // Selected range changed.
        if listItemFillText != "" {
            textView.selectedRange = NSRange(location: textView.selectedRange.location + listItemFillText.characters.count, length: textView.selectedRange.length)
        }
    }
    
    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()
        currentString.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    // MARK: - Other overrided


}
