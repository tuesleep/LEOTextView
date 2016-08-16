//
//  NCKTextStorage.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

class NCKTextStorage: NSTextStorage {
    var textView: NCKTextView!

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
        var currentNumber: Int?
        
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
                
                currentNumber = number
            }
        }
        
        beginEditing()
        
        currentString.replaceCharactersInRange(range, withString: str + listItemFillText)
        edited(.EditedCharacters, range: range, changeInLength: (str.characters.count + listItemFillText.characters.count) - range.length)
        
        endEditing()
        
        // Selected range changed.
        if listItemFillText != "" {
            let selectedRangeLocation = textView.selectedRange.location + listItemFillText.characters.count
            
            textView.selectedRange = NSRange(location: selectedRangeLocation, length: textView.selectedRange.length)
            
//            if currentNumber != nil {
//                // Reorder numbers after current line.
//                var afterStrings = textView.text.substringFromIndex(textView.text.startIndex.advancedBy(textView.selectedRange.location))
//                
//                let orderedListAfterItemsMatches = NCKTextUtil.markdownOrderedListAfterItemsRegularExpression.matchesInString(afterStrings, options: [], range: NSRange(location: 0, length: afterStrings.characters.count))
//                
//                for orderedListAfterItem in orderedListAfterItemsMatches {
//                    currentNumber! += 1
//                    
//                    let location = orderedListAfterItem.range.location
//                    let length = orderedListAfterItem.range.length
//                    
//                    afterStrings.replaceRange(Range(start: afterStrings.startIndex.advancedBy(location), end: afterStrings.startIndex.advancedBy(location + length)), with: "\n\(currentNumber!). ")
//                }
//            }
        }
    }
    
    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()
        currentString.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    // MARK: - Other overrided
    
    override func processEditing() {
        performReplacementsForRange(editedRange)
        
        super.processEditing()
    }

    // MARK: - Other methods
    
    func performReplacementsForRange(range: NSRange) {
        if range.length > 0 {
            // Add addition attributes.
            var attrValue: UIFont!
            
            switch textView.inputFontMode {
            case .Normal:
                attrValue = textView.normalFont
                break
            case .Bold:
                attrValue = textView.boldFont
                break
            case .Italic:
                attrValue = textView.italicFont
                break
            }
     
            self.addAttribute(NSFontAttributeName, value: attrValue, range: range)
        }
    }
    
}
