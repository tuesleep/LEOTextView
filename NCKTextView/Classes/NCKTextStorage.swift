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
    
    // Each dictionary in array. Key: location of NSRange, value: FontType
    var returnKeyDeleteEffectRanges: [[Int: NCKInputFontMode]] = []
    
    // MARK: - Must override
    override var string: String {
        return currentString.string
    }
    
    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return currentString.attributesAtIndex(location, effectiveRange: range)
    }
    
    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        // New item of list by increase
        var listItemFillText: NSString = ""
        
        // Current list item punctuation length
        var listPrefixItemLength = 0
        var deleteCurrentListPrefixItemByReturn = false
        var deleteCurrentListPrefixItemByBackspace = false
        
        // Unordered and Ordered list auto-complete support
        if NCKTextUtil.isReturn(str) {
            if textView.inputFontMode == .Title {
                textView.inputFontMode = .Normal
            }
            
            let objectLine = NCKTextUtil.objectLineAndIndexWithString(self.string, location: range.location).0
            
            switch NCKTextUtil.paragraphTypeWithObjectLine(objectLine) {
            case .NumberedList:
                var number = Int(objectLine.componentsSeparatedByString(".")[0])
                if number == nil {
                    break
                }
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
            firstLine.appendContentsOf(" ")
            
            let separates = firstLine.componentsSeparatedByString(" ").count
            let firstLineRange = NSMakeRange(0, NSString(string: firstLine).length)
    
            if separates == 2 && (NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(firstLine, options: .ReportProgress, range: firstLineRange).count > 0 || NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(firstLine, options: .ReportProgress, range: firstLineRange).count > 0) {
                // Delete mark
                deleteCurrentListPrefixItemByBackspace = true
                // a space char will deleting by edited operate, so we auto delete length needs subtraction one
                listPrefixItemLength = firstLineRange.length - 1
                listItemFillText = ""
            }
        }
        
        isChangeCharacters = true
        
        beginEditing()
        
        let finalStr: NSString = "\(str)"

        currentString.replaceCharactersInRange(range, withString: String(finalStr))

        edited(.EditedCharacters, range: range, changeInLength: (finalStr.length - range.length))
       
        endEditing()
        
        if deleteCurrentListPrefixItemByReturn {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength
            let deleteRange = NSRange(location: deleteLocation, length: listPrefixItemLength + 1)
            let deleteString = NSString(string: string).substringWithRange(deleteRange)
            
            undoSupportDeleteByReturnRange(deleteRange, withString: deleteString, selectedRangeLocationMove: -listPrefixItemLength)
            
            var effectIndex = deleteRange.location + 1
            
            if effectIndex < NSString(string: string).length {
                returnKeyDeleteEffectRanges.removeAll()
                
                while effectIndex < NSString(string: string).length {
                    guard let fontAfterDeleteText = self.attribute(NSFontAttributeName, atIndex: effectIndex, effectiveRange: nil) as? UIFont else {
                        continue
                    }
                    
                    var fontType: NCKInputFontMode = .Normal
                    
                    if fontAfterDeleteText.pointSize == textView.titleFont.pointSize {
                        fontType = .Title
                    } else if NCKTextUtil.isBoldFont(fontAfterDeleteText, boldFontName: textView.boldFont.fontName) {
                        fontType = .Bold
                    } else if NCKTextUtil.isItalicFont(fontAfterDeleteText, italicFontName: textView.italicFont.fontName) {
                        fontType = .Italic
                    }
                    
                    returnKeyDeleteEffectRanges.append([effectIndex: fontType])
                    
                    effectIndex += 1
                }
            }
            
        } else if deleteCurrentListPrefixItemByBackspace {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength
            let deleteRange = NSRange(location: deleteLocation, length: listPrefixItemLength)
            let deleteString = NSString(string: string).substringWithRange(deleteRange)
            
            undoSupportDeleteByBackspaceRange(deleteRange, withString: deleteString, selectedRangeLocationMove: -listPrefixItemLength)
        } else {
            // List item increase
            let listItemTextLength = NSString(string: listItemFillText).length
            
            if listItemTextLength > 0 {
                // Follow text cursor to new list item location.
                undoSupportAppendRange(NSMakeRange(range.location + NSString(string: str).length, 0), withString: String(listItemFillText), selectedRangeLocationMove: listItemTextLength)
            }
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
        if NSString(string: textView.text).length <= location {
            nck_location = location - 1
        }
        
        let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(string, location: nck_location)
        let titleFirstCharLocation = objectLineAndIndex.1
        
        let currentFont = self.textView.attributedText.attribute(NSFontAttributeName, atIndex: titleFirstCharLocation, effectiveRange: nil) as! UIFont
        if currentFont.pointSize == textView.titleFont.pointSize {
            return .Title
        }
        
        let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.string, location: location)
        
        let objectLine = NSString(string: self.string).substringWithRange(paragraphRange)

        return NCKTextUtil.paragraphTypeWithObjectLine(objectLine)
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
    
    // MARK: - Undo & Redo support
    
    func undoSupportDeleteByReturnRange(replaceRange: NSRange, withString deleteString: String, selectedRangeLocationMove: Int) {
        textView.undoManager?.prepareWithInvocationTarget(self).undoSupportDeleteByReturnRange(replaceRange, withString: deleteString, selectedRangeLocationMove: selectedRangeLocationMove)
        
        if textView.undoManager!.undoing {
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, 0), withString: deleteString)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
        } else {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(replaceRange, withString: "")
        }
    }
    
    func undoSupportDeleteByBackspaceRange(replaceRange: NSRange, withString deleteString: String, selectedRangeLocationMove: Int) {
        textView.undoManager?.prepareWithInvocationTarget(self).undoSupportDeleteByBackspaceRange(replaceRange, withString: deleteString, selectedRangeLocationMove: -selectedRangeLocationMove)
        
        if textView.undoManager!.undoing {
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, 0), withString: deleteString)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        } else {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(replaceRange, withString: "")
        }
    }
    
    func undoSupportAppendRange(replaceRange: NSRange, withString appendString: String, selectedRangeLocationMove: Int) {
        textView.undoManager?.prepareWithInvocationTarget(self).undoSupportAppendRange(replaceRange, withString: appendString, selectedRangeLocationMove: -selectedRangeLocationMove)
        
        if textView.undoManager!.undoing {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, NSString(string: appendString).length), withString: "")
        } else {
            safeReplaceCharactersInRange(replaceRange, withString: appendString)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        }
    }
    
    func safeReplaceCharactersInRange(range: NSRange, withString str: String) {
        let maxLength = range.location + range.length
        if maxLength <= NSString(string: string).length {
            replaceCharactersInRange(range, withString: str)
        }
    }

}
