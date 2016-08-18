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
    
    var isChangeCharacters: Bool = false
    
    // MARK: - Must override
    override var string: String {
        return currentString.string
    }
    
    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return currentString.attributesAtIndex(location, effectiveRange: range)
    }
    
    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        var listItemFillText: NSString = ""
        var currentNumber: Int?
        
        // Unordered and Ordered list auto-complete support
        if NCKTextUtil.isReturn(str) {
            var objectLine = NCKTextUtil.objectLineAndIndexWithString(self.string, location: range.location).0
            
            let objectLineRange = NSRange(location: 0, length: NSString(string: objectLine).length)
            
            // Check matches.
            let unorderedListMatches = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
            let orderedListMatches = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
            
            if unorderedListMatches.count > 0 {
                var listPrefixItem = objectLine.componentsSeparatedByString(" ")[0]
                listItemFillText = "\(listPrefixItem) "
            }
            
            if orderedListMatches.count > 0 {
                var number = Int(objectLine.componentsSeparatedByString(".")[0])
                number! += 1
                listItemFillText = "\(number!). "
                
                currentNumber = number
            }
        }
        
        isChangeCharacters = true
        
        beginEditing()
        
        let finalStr: NSString = "\(str)\(listItemFillText)"
        
        currentString.replaceCharactersInRange(range, withString: String(finalStr))
        edited(.EditedCharacters, range: range, changeInLength: (finalStr.length - range.length))
        
        endEditing()
        
        // Selected range changed.
        if listItemFillText != "" {
            let selectedRangeLocation = textView.selectedRange.location + listItemFillText.length
            
            textView.selectedRange = NSRange(location: selectedRangeLocation, length: textView.selectedRange.length)
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
        if range.length > 0 && isChangeCharacters {
            isChangeCharacters = false
            
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
