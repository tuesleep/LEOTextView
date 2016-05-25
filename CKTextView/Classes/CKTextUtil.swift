//
//  CKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

enum ListKeywordType {
    case NumberedList
}

class CKTextUtil: NSObject {
    class func isSpace(text: String) -> Bool
    {
        if text == " " {
            return true
        } else {
            return false
        }
    }
    
    class func isReturn(text: String) -> Bool
    {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isBackspace(text: String) -> Bool
    {
        if text == "" {
            return true
        } else {
            return false
        }
    }
    
    class func isEmptyLine(location:Int, textView: UITextView) -> Bool
    {
        let text = textView.text
        
        if text.endIndex == text.startIndex.advancedBy(location) {
            // last char of text.
            return true
        }
        
        let nextCharRange = Range(text.startIndex.advancedBy(location) ..< text.startIndex.advancedBy(location + 1))
        let keyChar = text.substringWithRange(nextCharRange)
        
        if keyChar == "\n" {
            return true
        }
        
        return false
    }
    
    class func isFirstLocationInLineWithLocation(location: Int, textView: UITextView) -> Bool
    {
        if location <= 0 {
            return true
        }
        
        let textString = textView.text
        
        let range: Range = Range(textString.startIndex.advancedBy(location - 1) ..< textString.startIndex.advancedBy(location))
        let keyChar = textView.text.substringWithRange(range)
        
        if keyChar == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func checkChangedTextInfoAndHandleMutilSelect(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> ([String], Bool, CGFloat)
    {
        let selectedRange = textView.selectedTextRange!
        
        let selectStartY = textView.caretRectForPosition(selectedRange.start).origin.y
        let selectEndY = textView.caretRectForPosition(selectedRange.end).origin.y
        
        var needsRemoveItemYArray = seletedPointYArrayWithTextView(textView, isContainFirstLine: false, sortByAsc: false)
        
        return (needsRemoveItemYArray, needsRemoveItemYArray.count > 0, selectStartY - selectEndY)
    }
    
    class func seletedPointYArrayWithTextView(textView: UITextView, isContainFirstLine containFirstLine: Bool, sortByAsc: Bool) -> [String]
    {
        let selectedRange = textView.selectedTextRange!
        
        let selectStartY = textView.caretRectForPosition(selectedRange.start).origin.y
        let selectEndY = textView.caretRectForPosition(selectedRange.end).origin.y
        
        var needsRemoveItemYArray: [String] = []
        
        var moveY = selectEndY
        
        let compareSelectStartY = selectStartY + 0.1
        
        if containFirstLine {
            needsRemoveItemYArray.append(String(Int(selectStartY)))
        }
        
        while moveY > compareSelectStartY {
            needsRemoveItemYArray.append(String(Int(moveY)))
            moveY -= textView.font!.lineHeight
        }
        
        if sortByAsc {
            needsRemoveItemYArray = needsRemoveItemYArray.sort({ ($0 as NSString).integerValue < ($1 as NSString).integerValue })
        }
        
        return needsRemoveItemYArray
    }
    
    class func heightWithText(text: String, textView: UITextView, listType: ListType, numberIndex: Int) -> (CGFloat, String)
    {
        let calcTextView = UITextView(frame: CGRect(x: 0, y: 0, width: textView.bounds.width, height: CGFloat.max))
        calcTextView.font = textView.font
    
        if listType != ListType.Text {
            let numberKeyword = "\(numberIndex). "
            
            let listTypeLengthDict = [ListType.Numbered: numberKeyword.characters.count, ListType.Bulleted: 2, ListType.Checkbox: 6]
            
            let lineHeight = calcTextView.font!.lineHeight
            let width = Int(lineHeight) + Int(lineHeight - 8)
            
            calcTextView.textContainer.exclusionPaths.append(UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: Int.max)))
            
            let prefixLength = listTypeLengthDict[listType]!
            
            calcTextView.text = text.substringFromIndex(text.startIndex.advancedBy(listTypeLengthDict[listType]!))
            
        } else {
            calcTextView.text = text
        }
        
        return (textHeightForTextView(calcTextView), calcTextView.text)
    }
    
    class func clearTextByRange(range: NSRange, textView: UITextView)
    {
        let clearRange = Range(textView.text.startIndex.advancedBy(range.location) ..< textView.text.startIndex.advancedBy(range.location + range.length))
        textView.text.replaceRange(clearRange, with: "")
    }
    
    class func textByRange(range: NSRange, text: String) -> String
    {
        let targetRange = Range(text.startIndex.advancedBy(range.location) ..< text.startIndex.advancedBy(range.location + range.length))
        return text.substringWithRange(targetRange)
    }
    
    class func typeForListKeywordWithLocation(location: Int, textView: UITextView) -> ListType
    {
        let checkArray = [("1.", 2, ListType.Numbered), ("*", 1, ListType.Bulleted), ("[]", 2, ListType.Checkbox)]
        
        for (_, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            let keyChars = self.keyCharsWithLocation(location, textView: textView, length: length)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    private class func keyCharsWithLocation(location: Int, textView: UITextView, length: Int) -> String
    {
        guard location >= length && CKTextUtil.isFirstLocationInLineWithLocation(location - length, textView: textView) else { return "" }
        
        let textString = textView.text
        let range: Range = Range(textString.startIndex.advancedBy(location - length) ..< textString.startIndex.advancedBy(location))
        let keyChars = textView.text.substringWithRange(range)
        
        return keyChars
    }
    
    class func textHeightForTextView(textView: UITextView) -> CGFloat
    {
        let textHeight = textView.layoutManager.usedRectForTextContainer(textView.textContainer).height
        return textHeight
    }
    
    class func cursorPointInTextView(textView: UITextView) -> CGPoint
    {
        return textView.caretRectForPosition(textView.selectedTextRange!.start).origin
        
    }
    
    class func typeOfCharacter(character: String, numberIndex: Int) -> ListType
    {
        let numberKeyword = "\(numberIndex). "
        
        let checkArray = [(numberKeyword, numberKeyword.characters.count, ListType.Numbered), ("* ", 2, ListType.Bulleted), ("- [ ] ", 6, ListType.Checkbox), ("- [x] ", 6, ListType.Checkbox)]
        
        for (_, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            if character.characters.count < length {
                continue
            }
            
            let range: Range = Range(character.startIndex ..< character.startIndex.advancedBy(length))
            let keyChars = character.substringWithRange(range)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    class func resetKeyYSetItem(item: BaseListItem, startY: CGFloat, textHeight: CGFloat, lineHeight: CGFloat)
    {
        var keyYSet: Set<CGFloat> = Set()
        
        var y = startY
        var moveY = textHeight
        
        while moveY >= lineHeight {
            keyYSet.insert(y)
            y += lineHeight
            
            moveY -= lineHeight
        }
        
        item.keyYSet = keyYSet
    }
}
