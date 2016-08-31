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
        
        var listPrefixItemLength = 0
        var deleteCurrentListPrefixItem = false
        
        // Unordered and Ordered list auto-complete support
        if NCKTextUtil.isReturn(str) {
            if textView.inputFontMode == .Title {
                textView.inputFontMode = .Normal
            }
            
            let objectLine = NCKTextUtil.objectLineAndIndexWithString(self.string, location: range.location).0
            
            switch currentParagraphTypeWithLocation(range.location) {
            case .NumberedList:
                var number = Int(objectLine.componentsSeparatedByString(".")[0])
                
                listPrefixItemLength = NSString(string: "\(number!). ").length
                
                number! += 1
                listItemFillText = "\(number!). "
                break
            case .BulletedList, .DashedList:
                let listPrefixItem = objectLine.componentsSeparatedByString(" ")[0]
                listItemFillText = "\(listPrefixItem) "
                
                listPrefixItemLength = listItemFillText.length
                
                break
            default:
                break
            }
            
            if listPrefixItemLength == NSString(string: objectLine).length {
                let remainText: NSString = NSString(string: self.string).substringFromIndex(range.location)
                if remainText == "" || remainText.rangeOfString("\n").location == 0 {
                    deleteCurrentListPrefixItem = true
                    listItemFillText = ""
                }
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
    
        if deleteCurrentListPrefixItem {
//            let deleteRange = NSRange(location: range.location - listPrefixItemLength, length: listPrefixItemLength)
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
        if isChangeCharacters && editedRange.length > 0 {
            isChangeCharacters = false
            performReplacementsForRange(editedRange, mode: textView.inputFontMode)
        }
        
        super.processEditing()
    }

    // MARK: - Other methods
    
    func currentParagraphTypeWithLocation(location: Int) -> NCKInputParagraphType {
        if self.textView.text == "" {
            return (self.textView.inputFontMode) == .Title ? .Title : .Body
        }
        
        var nck_location = location
        if NSString(string: self.textView.text).length <= location {
            nck_location = location - 1
        }
        
        let currentFont = self.textView.attributedText.attribute(NSFontAttributeName, atIndex: nck_location, effectiveRange: nil) as! UIFont
        if currentFont.pointSize == textView.titleFont.pointSize {
            return .Title
        }
        
        let objectLine = NCKTextUtil.objectLineAndIndexWithString(self.string, location: location).0
        let ns_objectLine = NSString(string: objectLine)
        
        let objectLineRange = NSRange(location: 0, length: NSString(string: objectLine).length)
        
        // Check matches.
        let unorderedListMatches = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLine, options: [], range: objectLineRange)
        if unorderedListMatches.count > 0 {
            let firstChar = ns_objectLine.substringToIndex(1)
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
    
    func performReplacementsForRange(range: NSRange, mode: NCKInputFontMode) {
        if range.length > 0 {
            // Add addition attributes.
            var attrValue: UIFont!
            
            switch mode {
            case .Normal:
                attrValue = textView.normalFont
                break
            case .Bold:
                attrValue = textView.boldFont
                break
            case .Italic:
                attrValue = textView.italicFont
                break
            case .Title:
                attrValue = textView.titleFont
                break
            }
     
            self.addAttribute(NSFontAttributeName, value: attrValue, range: range)
        }
    }
}
