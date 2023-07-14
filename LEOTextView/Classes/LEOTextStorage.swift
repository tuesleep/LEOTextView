//
//  LEOTextStorage.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

class LEOTextStorage: NSTextStorage {
    var textView: LEOTextView!

    var currentString: NSMutableAttributedString = NSMutableAttributedString()

    var isChangeCharacters: Bool = false

    // Each dictionary in array. Key: location of NSRange, value: FontType
    var returnKeyDeleteEffectRanges: [[Int: LEOInputFontMode]] = []

    // MARK: - Must override
    override var string: String {
        return currentString.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return currentString.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        // New item of list by increase
        var listItemFillText: NSString = ""

        // Current list item punctuation length
        var listPrefixItemLength = 0
        var deleteCurrentListPrefixItemByReturn = false
        var deleteCurrentListPrefixItemByBackspace = false

        // Unordered and Ordered list auto-complete support
        if LEOTextUtil.isReturn(str) {
            if textView.inputFontMode == .title {
                textView.inputFontMode = .normal
            }

            let objectLineAndIndex = LEOTextUtil.objectLineAndIndexWithString(self.string, location: range.location)
            let objectLine = objectLineAndIndex.0
            let objectIndex = objectLineAndIndex.1

            switch LEOTextUtil.paragraphTypeWithObjectLine(objectLine) {
            case .numberedList:
                var number = Int(objectLine.components(separatedBy: ".")[0])
                if number == nil {
                    break
                }
                listPrefixItemLength = "\(number!). ".length()

                // number changed.
                number! += 1
                listItemFillText = "\(number!). " as NSString
                break
            case .bulletedList, .dashedList:
                let listPrefixItem = objectLine.components(separatedBy: " ")[0]
                listItemFillText = "\(listPrefixItem) " as NSString

                listPrefixItemLength = listItemFillText.length

                break
            default:
                break
            }

            let separateds = objectLine.components(separatedBy: " ")
            if separateds.count >= 2 {
                let objectLineRange = NSMakeRange(0, objectLine.length())
                if separateds[1] == "" && (LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: objectLine, options: .reportProgress, range: objectLineRange).count > 0 || LEOTextUtil.markdownOrderedListRegularExpression.matches(in: objectLine, options: .reportProgress, range: objectLineRange).count > 0) {

                    let lastIndex = objectIndex + objectLine.length()
                    let isEndOfText = lastIndex >= string.length()
                    var isReturnAtNext = false

                    if !isEndOfText {
                        isReturnAtNext = LEOTextUtil.isReturn(NSString(string: string).substring(with: NSMakeRange(lastIndex, 1)))
                    }

                    if isEndOfText || isReturnAtNext {
                        // Delete mark
                        deleteCurrentListPrefixItemByReturn = true
                        listPrefixItemLength = listItemFillText.length
                        listItemFillText = ""
                    }
                }
            }
        } else if LEOTextUtil.isBackspace(str) && range.length == 1 {
            var firstLine = LEOTextUtil.objectLineWithString(self.textView.text, location: range.location)
            firstLine.append(" ")

            let separates = firstLine.components(separatedBy: " ").count
            let firstLineRange = NSMakeRange(0, firstLine.length())

            if separates == 2 && (LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: firstLine, options: .reportProgress, range: firstLineRange).count > 0 || LEOTextUtil.markdownOrderedListRegularExpression.matches(in: firstLine, options: .reportProgress, range: firstLineRange).count > 0) {
                // Delete mark
                deleteCurrentListPrefixItemByBackspace = true
                // a space char will deleting by edited operate, so we auto delete length needs subtraction one
                listPrefixItemLength = firstLineRange.length - 1
                listItemFillText = ""
            }
        }

        isChangeCharacters = true

        beginEditing()

        let finalStr: NSString = "\(str)" as NSString

        currentString.replaceCharacters(in: range, with: String(finalStr))

        edited(.editedCharacters, range: range, changeInLength: (finalStr.length - range.length))

        endEditing()

        if textView.undoManager!.isRedoing {
            return
        }

        if deleteCurrentListPrefixItemByReturn {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength
            let deleteRange = NSRange(location: deleteLocation, length: listPrefixItemLength + 1)
            let deleteString = NSString(string: string).substring(with: deleteRange)

            undoSupportReplaceRange(deleteRange, withAttributedString: NSAttributedString(), oldAttributedString: NSAttributedString(string: deleteString), selectedRangeLocationMove: -(deleteLocation > 0 ? listPrefixItemLength + 1 : listPrefixItemLength))

            var effectIndex = deleteRange.location + 1

            if effectIndex < string.length() {
                returnKeyDeleteEffectRanges.removeAll()

                while effectIndex < string.length() {
                    guard let fontAfterDeleteText = self.safeAttribute(NSAttributedString.Key.font.rawValue, atIndex: effectIndex, effectiveRange: nil, defaultValue: nil) as? UIFont else {
                        continue
                    }

                    var fontType: LEOInputFontMode = .normal

                    if fontAfterDeleteText.pointSize == textView.titleFont.pointSize {
                        fontType = .title
                    } else if LEOTextUtil.isBoldFont(fontAfterDeleteText, boldFontName: textView.boldFont.fontName) {
                        fontType = .bold
                    } else if LEOTextUtil.isItalicFont(fontAfterDeleteText, italicFontName: textView.italicFont.fontName) {
                        fontType = .italic
                    }

                    returnKeyDeleteEffectRanges.append([effectIndex: fontType])

                    effectIndex += 1
                }
            }

        } else if deleteCurrentListPrefixItemByBackspace {
            // Delete list item characters.
            let deleteLocation = range.location - listPrefixItemLength
            let deleteRange = NSRange(location: deleteLocation, length: listPrefixItemLength)
            let deleteString = NSString(string: string).substring(with: deleteRange)

            undoSupportReplaceRange(deleteRange, withAttributedString: NSAttributedString(), oldAttributedString: NSAttributedString(string: deleteString), selectedRangeLocationMove: -listPrefixItemLength)
        } else {
            // List item increase
            let listItemTextLength = listItemFillText.length

            if listItemTextLength > 0 {
                // Follow text cursor to new list item location.
                undoSupportAppendRange(NSMakeRange(range.location + str.length(), 0), withString: String(listItemFillText), selectedRangeLocationMove: listItemTextLength)
            }
        }
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        guard currentString.string.length() > range.location else {
            return
        }

        beginEditing()

        currentString.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)

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

    func currentParagraphTypeWithLocation(_ location: Int) -> LEOInputParagraphType {
        if self.textView.text == "" {
            return self.textView.inputFontMode == .title ? .title : .body
        }

        let objectLineAndIndex = LEOTextUtil.objectLineAndIndexWithString(string, location: location)
        let titleFirstCharLocation = objectLineAndIndex.1

        let currentFont = self.textView.attributedText.safeAttribute(NSAttributedString.Key.font.rawValue, atIndex: titleFirstCharLocation, effectiveRange: nil, defaultValue: textView.normalFont) as! UIFont
        if currentFont.pointSize == textView.titleFont.pointSize {
            return .title
        }

        let paragraphRange = LEOTextUtil.paragraphRangeOfString(self.string, location: location)

        let objectLine = NSString(string: self.string).substring(with: paragraphRange)

        return LEOTextUtil.paragraphTypeWithObjectLine(objectLine)
    }

    func performReplacementsForRange(_ range: NSRange, mode: LEOInputFontMode) {
        if range.length > 0 {
            // Add addition attributes.
            var attrValue: UIFont!

            switch mode {
            case .normal:
                attrValue = textView.normalFont
                break
            case .bold:
                attrValue = textView.boldFont
                break
            case .italic:
                attrValue = textView.italicFont
                break
            case .title:
                attrValue = textView.titleFont
                break
            }

            safeAddAttributes([NSAttributedString.Key.font : attrValue], range: range)
        }
    }

    // MARK: - Undo & Redo support

    func undoSupportChangeWithRange(_ range: NSRange, toMode targetMode: Int, currentMode: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportChangeWithRange(range, toMode: targetMode, currentMode: currentMode)
        })

        if textView.undoManager!.isUndoing {
            performReplacementsForRange(range, mode: LEOInputFontMode(rawValue: currentMode)!)
        } else {
            performReplacementsForRange(range, mode: LEOInputFontMode(rawValue: targetMode)!)
        }
    }

    func undoSupportReplaceRange(_ replaceRange: NSRange, withAttributedString attributedStr: NSAttributedString, oldAttributedString: NSAttributedString, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportReplaceRange(replaceRange, withAttributedString: attributedStr, oldAttributedString: oldAttributedString, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            let targetSelectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, textView.selectedRange.length)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, attributedStr.string.length()), withAttributedString: oldAttributedString)
            textView.selectedRange = targetSelectedRange
        } else {
            let targetSelectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, textView.selectedRange.length)
            safeReplaceCharactersInRange(replaceRange, withAttributedString: attributedStr)
            textView.selectedRange = targetSelectedRange
        }
    }

    func undoSupportAppendRange(_ replaceRange: NSRange, withString str: String, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportAppendRange(replaceRange, withString: str, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, str.length()), withString: "")
        } else {
            safeReplaceCharactersInRange(replaceRange, withString: str)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        }
    }

    func undoSupportAppendRange(_ replaceRange: NSRange, withAttributedString attributedStr: NSAttributedString, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportAppendRange(replaceRange, withAttributedString: attributedStr, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, attributedStr.string.length()), withAttributedString: NSAttributedString())
        } else {
            safeReplaceCharactersInRange(replaceRange, withAttributedString: attributedStr)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        }
    }

    func undoSupportMadeIndenationRange(_ range: NSRange, headIndent: CGFloat) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportMadeIndenationRange(range, headIndent: headIndent)
        })

        let paragraphStyle = textView.mutableParargraphWithDefaultSetting()

        if textView.undoManager!.isUndoing {
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        } else {
            paragraphStyle.headIndent = headIndent + textView.normalFont.lineHeight
            paragraphStyle.firstLineHeadIndent = textView.normalFont.lineHeight
        }

      safeAddAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: range)
    }

    func undoSupportResetIndenationRange(_ range: NSRange, headIndent: CGFloat) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportResetIndenationRange(range, headIndent: headIndent)
        })

        let paragraphStyle = textView.mutableParargraphWithDefaultSetting()

        if textView.undoManager!.isUndoing {
            paragraphStyle.headIndent = headIndent + textView.normalFont.lineHeight
            paragraphStyle.firstLineHeadIndent = textView.normalFont.lineHeight
        } else {
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        }

      safeAddAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: range)
    }
}
