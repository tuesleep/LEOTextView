//
//  LEOTextUtil.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

class LEOTextUtil: NSObject {
    static let markdownUnorderedListRegularExpression = try! NSRegularExpression(pattern: "^[-*••∙●] ", options: .caseInsensitive)
    static let markdownOrderedListRegularExpression = try! NSRegularExpression(pattern: "^\\d*\\. ", options: .caseInsensitive)
    static let markdownOrderedListAfterItemsRegularExpression = try! NSRegularExpression(pattern: "\\n\\d*\\. ", options: .caseInsensitive)

    class func isReturn(_ text: String) -> Bool {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }

    class func isBackspace(_ text: String) -> Bool {
        if text == "" {
            return true
        } else {
            return false
        }
    }

    class func isSelectedTextWithTextView(_ textView: UITextView) -> Bool {
        let length = textView.selectedRange.length
        return length > 0
    }

    class func objectLineAndIndexWithString(_ string: String, location: Int) -> (String, Int) {
        let ns_string = NSString(string: string)

        var objectIndex: Int = 0
        var objectLine = ns_string.substring(to: location)

        let textSplits = objectLine.components(separatedBy: "\n")
        if textSplits.count > 0 {
            let currentObjectLine = textSplits[textSplits.count - 1]

            objectIndex = objectLine.length() - currentObjectLine.length()
            objectLine = currentObjectLine
        }

        return (objectLine, objectIndex)
    }

    class func objectLineWithString(_ string: String, location: Int) -> String {
        return objectLineAndIndexWithString(string, location: location).0
    }

    class func lineEndIndexWithString(_ string: String, location: Int) -> Int {
        let remainText: NSString = NSString(string: string).substring(from: location) as NSString

        var nextLineBreakLocation = remainText.range(of: "\n").location
        nextLineBreakLocation = (nextLineBreakLocation == NSNotFound) ? string.length() : nextLineBreakLocation + location

        return nextLineBreakLocation
    }

    class func paragraphRangeOfString(_ string: String, location: Int) -> NSRange {
        let startLocation = objectLineAndIndexWithString(string, location: location).1
        let endLocation = lineEndIndexWithString(string, location: location)

        return NSMakeRange(startLocation, endLocation - startLocation)
    }

    class func currentParagraphStringOfString(_ string: String, location: Int) -> String {
        return NSString(string: string).substring(with: paragraphRangeOfString(string, location: location))
    }

    /**
     Just return ListTypes.
     */
    class func paragraphTypeWithObjectLine(_ objectLine: String) -> LEOInputParagraphType {
        let objectLineRange = NSMakeRange(0, objectLine.length())

        let unorderedListMatches = LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: objectLine, options: [], range: objectLineRange)
        if unorderedListMatches.count > 0 {
            let firstChar = NSString(string: objectLine).substring(to: 1)
            if firstChar == "-" {
                return .dashedList
            } else {
                return .bulletedList
            }
        }

        let orderedListMatches = LEOTextUtil.markdownOrderedListRegularExpression.matches(in: objectLine, options: [], range: objectLineRange)
        if orderedListMatches.count > 0 {
            return .numberedList
        }

        return .body
    }

    class func isListParagraph(_ objectLine: String) -> Bool {
        let objectLineRange = NSMakeRange(0, objectLine.length())

        let isCurrentOrderedList = LEOTextUtil.markdownOrderedListRegularExpression.matches(in: objectLine, options: [], range: objectLineRange).count > 0
        if isCurrentOrderedList {
            return true
        }

        let isCurrentUnorderedList = LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: objectLine, options: [], range: objectLineRange).count > 0
        if isCurrentUnorderedList {
            return true
        }

        return false
    }

    class func isBoldFont(_ font: UIFont, boldFontName: String) -> Bool {
        if font.fontName == boldFontName {
            return true
        }

        let keywords = ["bold", "medium"]

        // At chinese language: PingFangSC-Light is normal, PingFangSC-Regular is bold

        return isSpecialFont(font, keywords: keywords)
    }

    class func isItalicFont(_ font: UIFont, italicFontName: String) -> Bool {
        if font.fontName == italicFontName {
            return true
        }

        let keywords = ["italic"]

        return isSpecialFont(font, keywords: keywords)
    }

    class func isSpecialFont(_ font: UIFont, keywords: [String]) -> Bool {
        let fontName = NSString(string: font.fontName)

        for keyword in keywords {
            if fontName.range(of: keyword, options: .caseInsensitive).location != NSNotFound {
                return true
            }
        }

        return false
    }

    class func keyboardWindow() -> UIWindow? {
        var keyboardWin: UIWindow?

        UIApplication.shared.windows.forEach {
            if String(describing: type(of: $0)) == "UITextEffectsWindow" {
                keyboardWin = $0
                return
            }
        }

        return keyboardWin
    }

}