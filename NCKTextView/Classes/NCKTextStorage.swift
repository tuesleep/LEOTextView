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
        var deleteCurrentListPrefixItemByReturn = false
        var deleteCurrentListPrefixItemByBackspace = false
        
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
                
                // number changed.
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
            
            let separateds = objectLine.componentsSeparatedByString(" ")
            if separateds.count >= 2 {
                let objectLineRange = NSMakeRange(0, NSString(string: objectLine).length)
                if separateds[1] == "" && (NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLine, options: .ReportProgress, range: objectLineRange).count > 0 || NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLine, options: .ReportProgress, range: objectLineRange).count > 0) {
                    // Delete mark
                    deleteCurrentListPrefixItemByReturn = true
                    listPrefixItemLength = listItemFillText.length
                    listItemFillText = ""
                }
            }
        } else if NCKTextUtil.isBackspace(str) && range.length == 1 {
            var firstLine = NCKTextUtil.objectLineWithString(self.textView.text, location: range.location)
            var firstLineRange = NSMakeRange(0, NSString(string: firstLine).length)
            // FIXME: 判断方法有问题。
            if NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(firstLine, options: .ReportProgress, range: firstLineRange).count > 0 || NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(firstLine, options: .ReportProgress, range: firstLineRange).count > 0 {
                // Delete mark
                deleteCurrentListPrefixItemByBackspace = true
                listPrefixItemLength = firstLineRange.length
                listItemFillText = ""
            }
        }
        
        isChangeCharacters = true
        
        beginEditing()
        
        let finalStr: NSString = "\(str)\(listItemFillText)"

        currentString.replaceCharactersInRange(range, withString: String(finalStr))

        edited(.EditedCharacters, range: range, changeInLength: (finalStr.length - range.length))
       
        endEditing()
        
        // Selected range changed.
        if NSString(string: listItemFillText).length > 0 {
            let selectedRangeLocation = textView.selectedRange.location + listPrefixItemLength
            
            textView.selectedRange = NSRange(location: selectedRangeLocation, length: textView.selectedRange.length)
        }
    
        if deleteCurrentListPrefixItemByReturn {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength
            
            textView.selectedRange = NSRange(location: deleteLocation - 1, length: 0)
            
            let deleteRange = NSRange(location: deleteLocation, length: listPrefixItemLength + 1)
            self.deleteCharactersInRange(deleteRange)
        } else if deleteCurrentListPrefixItemByBackspace {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength + 1
            
            print("deleteLocation: \(deleteLocation)")
        }
    }
    
    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        guard NSString(string: currentString.string).length > range.location else {
            return
        }
        
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
            return self.textView.inputFontMode == .Title ? .Title : .Body
        }
        
        var nck_location = location
        if NSString(string: self.textView.text).length <= location {
            nck_location = location - 1
        }
        
        let currentFont = self.textView.attributedText.attribute(NSFontAttributeName, atIndex: nck_location, effectiveRange: nil) as! UIFont
        if currentFont.pointSize == textView.titleFont.pointSize {
            return .Title
        }
        
        let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.string, location: location)
        let paragraphString = NSString(string: self.string).substringWithRange(paragraphRange)
        
        let objectLineRange = NSRange(location: 0, length: NSString(string: paragraphString).length)
        
        // Check matches.
        let unorderedListMatches = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(paragraphString, options: [], range: objectLineRange)
        if unorderedListMatches.count > 0 {
            let firstChar = NSString(string: paragraphString).substringToIndex(1)
            if firstChar == "-" {
                return .DashedList
            } else {
                return .BulletedList
            }
        }
        
        let orderedListMatches = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(paragraphString, options: [], range: objectLineRange)
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
