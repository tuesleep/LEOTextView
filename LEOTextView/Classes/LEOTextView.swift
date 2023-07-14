//
//  LEOTextView.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

open class LEOTextView: UITextView {
    // MARK: - Public properties

    open var nck_delegate: UITextViewDelegate?

    open var inputFontMode: LEOInputFontMode = .normal
    open var defaultAttributesForLoad: [NSAttributedString.Key : AnyObject] = [:]
    open var selectMenuItems: [LEOInputFontMode] = [.bold, .italic]

    // Custom fonts
    open var normalFont: UIFont = UIFont.systemFont(ofSize: 17)
    open var titleFont: UIFont = UIFont.boldSystemFont(ofSize: 18)
    open var boldFont: UIFont = UIFont.boldSystemFont(ofSize: 17)
    open var italicFont: UIFont = UIFont.italicSystemFont(ofSize: 17)

    // MARK: - instance relations

    var nck_textStorage: LEOTextStorage!

    var currentAttributesDataWithPasteboard: [Dictionary<String, AnyObject>]?

    let nck_attributesDataWithPasteboardUserDefaultKey = "leo_attributesDataWithPasteboardUserDefaultKey"

    // MARK: - Init methods

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        let nonenullTextContainer = (textContainer == nil) ? NSTextContainer() : textContainer!

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(nonenullTextContainer)

        let textStorage = LEOTextStorage()
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: nonenullTextContainer)

        textStorage.textView = self

        // TextView property set
        delegate = self
        nck_textStorage = textStorage

        customTextView()
    }

    public init(normalFont: UIFont, titleFont: UIFont, boldFont: UIFont, italicFont: UIFont) {
        super.init(frame: CGRect.zero, textContainer: NSTextContainer())

        self.font = normalFont
        self.normalFont = normalFont
        self.titleFont = titleFont
        self.boldFont = boldFont
        self.italicFont = italicFont
    }

    deinit {
        self.removeToolbarNotifications()
    }
    
    // MARK: - Override super
    
    override open func caretRect(for position: UITextPosition) -> CGRect {
        var originalRect = super.caretRect(for: position)
        originalRect.size.height = (font == nil ? 16 : font!.lineHeight) + 2
        return originalRect;
    }

    // MARK: - Custom text view

    func customTextView() {
        customSelectionMenu()
    }

    func customSelectionMenu() {
        let menuController = UIMenuController.shared
        var menuItems = [UIMenuItem]()

        selectMenuItems.forEach {
            switch $0 {
            case .bold:
                menuItems.append(UIMenuItem(title: NSLocalizedString("Bold", comment: "Bold"), action: #selector(self.boldButtonAction)))
                break
            case .italic:
                menuItems.append(UIMenuItem(title: NSLocalizedString("Italic", comment: "Italic"), action: #selector(self.italicButtonAction)))
                break
            default:
                break
            }
        }

        menuController.menuItems = menuItems
    }

    // MARK: - Public APIs

    // MARK: Type transform

    open func changeCurrentParagraphTextWithInputFontMode(_ mode: LEOInputFontMode) {
        let paragraphRange = LEOTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
        let currentMode = inputModeWithIndex(paragraphRange.location)

        nck_textStorage.undoSupportChangeWithRange(paragraphRange, toMode: mode.rawValue, currentMode: currentMode.rawValue)
    }

    open func changeSelectedTextWithInputFontMode(_ mode: LEOInputFontMode) {
        let currentMode = inputModeWithIndex(selectedRange.location)
        nck_textStorage.undoSupportChangeWithRange(selectedRange, toMode: mode.rawValue, currentMode: currentMode.rawValue)
    }

    /**
     Change paragraph to list or body by automatic with current selected range.

     - Parameter isOrderedList Mark current list operate is ordered or not.
     - Parameter listPrefix Target for defined unordered list characters.

     Example:

     ```
     changeCurrentParagraphToOrderedList(true, listPrefix: "1. ")

     changeCurrentParagraphToOrderedList(false, listPrefix: "- ")
     ```

     */
    open func changeCurrentParagraphToOrderedList(orderedList isOrderedList: Bool, listPrefix: String) {
        // New method based on selectedRange text, and enumerate each line
        // Find target text
        var targetText: NSString!
        var targetRange: NSRange!

        let objectLineAndIndex = LEOTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
        let objectIndex = objectLineAndIndex.1

        if selectedRange.length == 0 {
            // current paragraph
            targetText = LEOTextUtil.currentParagraphStringOfString(text, location: selectedRange.location) as NSString
            targetRange = NSRange(location: objectIndex, length: targetText.length)
        } else {
            var lastIndex = selectedRange.location + selectedRange.length
            lastIndex = LEOTextUtil.lineEndIndexWithString(text, location: lastIndex)
            targetRange = NSRange(location: objectIndex, length: lastIndex - objectIndex)
            targetText = (text as NSString).substring(with: targetRange) as NSString
        }

        // Confirm current is To list or To body by first line
        let objectLineRange = NSRange(location: 0, length: targetText.length)

        let isCurrentOrderedList = LEOTextUtil.markdownOrderedListRegularExpression.matches(in: String(targetText), options: [], range: objectLineRange).count > 0
        let isCurrentUnorderedList = LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: String(targetText), options: [], range: objectLineRange).count > 0

        let isListNow = (isCurrentOrderedList || isCurrentUnorderedList)
        let isTransformToList = (isOrderedList && !isCurrentOrderedList) || (!isOrderedList && !isCurrentUnorderedList)

        var numberedIndex = 1
        var replacedContents: [NSString] = []
        // enumerate each line
        targetText.enumerateLines { (line, stop) in
            var currentLine: NSString = line as NSString

            // Clear old list characters if exist
            if LEOTextUtil.isListParagraph(line) {
                currentLine = currentLine.substring(from: currentLine.range(of: " ").location + 1) as NSString
            }

            // Appending new list characters if needed
            if isTransformToList {
                if isOrderedList {
                    currentLine = NSString(string: "\(numberedIndex). ").appending(String(currentLine)) as NSString
                    numberedIndex += 1
                } else {
                    currentLine = NSString(string: listPrefix).appending(String(currentLine)) as NSString
                }
            }

            replacedContents.append(currentLine)
        }

        var replacedContent = NSArray(array: replacedContents).componentsJoined(by: "\n")

        if targetText.length == 0 && replacedContent.length() == 0 {
            replacedContent = listPrefix
        }

        // Replace paragraph
        nck_textStorage.undoSupportReplaceRange(targetRange, withAttributedString: NSAttributedString(string: replacedContent, attributes: defaultAttributesForLoad), oldAttributedString: NSAttributedString(string: String(targetText), attributes: defaultAttributesForLoad), selectedRangeLocationMove: replacedContent.length() - targetText.length)

        if isListNow {
            // Already list paragraph.
            let listPrefixString: NSString = NSString(string: objectLineAndIndex.0.components(separatedBy: " ")[0]).appending(" ") as NSString

            // Handle head indent of paragraph.
            nck_textStorage.undoSupportResetIndenationRange(NSMakeRange(targetRange.location, replacedContent.length()), headIndent: listPrefixString.size(withAttributes: [NSAttributedString.Key.font: normalFont]).width)
        }

        if isTransformToList {
            // Become list paragraph.
            let listPrefixString = NSString(string: listPrefix)

            // Handle head indent of paragraph.
            nck_textStorage.undoSupportMadeIndenationRange(NSMakeRange(targetRange.location, replacedContent.length()), headIndent: listPrefixString.size(withAttributes: [NSAttributedString.Key.font: normalFont]).width)
        }

    }

    // MARK: About text attributes and JSON

    open func textAttributesDataWithAttributedString(_ attributedString: NSAttributedString) -> [Dictionary<String, AnyObject>] {
        var attributesData: [Dictionary<String, AnyObject>] = []

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.string.length()), options: .reverse) { (attr, range, mutablePointer) in
            attr.keys.forEach {
                var attribute = [String: AnyObject]()

                // Common name property
                attribute["name"] = $0 as AnyObject?
                // Common range property
                attribute["location"] = range.location as AnyObject?
                attribute["length"] = range.length as AnyObject?

                if $0 == NSAttributedString.Key.font {
                    let currentFont = attr[$0] as! UIFont

                    var fontType = "normal";

                    if (currentFont.pointSize == self.titleFont.pointSize) {
                        fontType = "title"
                    } else if (LEOTextUtil.isBoldFont(currentFont, boldFontName: self.boldFont.fontName)) {
                        fontType = "bold"
                    } else if (LEOTextUtil.isItalicFont(currentFont, italicFontName: self.italicFont.fontName)) {
                        fontType = "italic"
                    }

                    // Normal font properties saved.
                    attribute["fontType"] = fontType as AnyObject?

                    attributesData.append(attribute)
                }
                // Paragraph indent saved
                else if $0 == NSAttributedString.Key.paragraphStyle {
                    let paragraphType = self.nck_textStorage.currentParagraphTypeWithLocation(range.location)

                    if paragraphType == .bulletedList || paragraphType == .dashedList || paragraphType == .numberedList {
                        attribute["listType"] = paragraphType.rawValue as AnyObject?
                        attributesData.append(attribute)
                    }
                }
            }
        }

        return attributesData
    }

    /**
        All of attributes about current text by JSON
     */
    open func textAttributesJSON() -> String {
        let attributesData: [Dictionary<String, AnyObject>] = textAttributesDataWithAttributedString(attributedText)

        return LEOTextView.jsonStringWithAttributesData(attributesData, text: text)
    }

    open func setAttributeTextWithJSONString(_ jsonString: String) {
        let jsonDict: [String: AnyObject] = try! JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String : AnyObject]

        let text = jsonDict["text"] as! String
        self.attributedText = NSAttributedString(string: text, attributes: self.defaultAttributesForLoad)

        setAttributesWithJSONString(jsonString)
    }

    open func setAttributesWithJSONString(_ jsonString: String) {
        let attributes = LEOTextView.attributesWithJSONString(jsonString)
        let textString = NSString(string: LEOTextView.textWithJSONString(jsonString))

        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)

            if attributeName == NSAttributedString.Key.font.rawValue {
                let currentFont = fontOfTypeWithAttribute(attribute)
                textStorage.addAttribute(NSAttributedString.Key(rawValue: attributeName), value: currentFont, range: range)
            } else if attributeName == NSAttributedString.Key.paragraphStyle.rawValue {
                let listTypeRawValue = attribute["listType"]

                if listTypeRawValue != nil {
                    let listType = LEOInputParagraphType(rawValue: listTypeRawValue as! Int)
                    var listPrefixWidth: CGFloat = 0

                    if listType == .numberedList {
                        var listPrefixString = textString.substring(with: range).components(separatedBy: " ")[0]
                        listPrefixString.append(" ")
                        listPrefixWidth = NSString(string: listPrefixString).size(withAttributes: [NSAttributedString.Key.font: normalFont]).width
                    } else {
                        listPrefixWidth = NSString(string: "• ").size(withAttributes: [NSAttributedString.Key.font: normalFont]).width
                    }

                    let lineHeight = normalFont.lineHeight

                    let paragraphStyle = mutableParargraphWithDefaultSetting()
                    paragraphStyle.headIndent = listPrefixWidth + lineHeight
                    paragraphStyle.firstLineHeadIndent = lineHeight
                    textStorage.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: normalFont], range: range)
                }
            }
        }
    }

    open class func addAttributesWithAttributedString(_ attributedString: NSAttributedString, jsonString: String, normalFont: UIFont, titleFont: UIFont, boldFont: UIFont, italicFont: UIFont, defaultParagraphStyle: NSParagraphStyle?) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)

        let attributes = LEOTextView.attributesWithJSONString(jsonString)
        let textString = NSString(string: LEOTextView.textWithJSONString(jsonString))

        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range  = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)

            if attributeName == NSAttributedString.Key.font.rawValue {
                let fontType = attribute["fontType"] as? String
                var currentFont = normalFont

                if fontType == "title" {
                    currentFont = titleFont
                } else if fontType == "bold" {
                    currentFont = boldFont
                } else if fontType == "italic" {
                    currentFont = italicFont
                }

                mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: currentFont, range: range)
            } else if attributeName == NSAttributedString.Key.paragraphStyle.rawValue {
                let listTypeRawValue = attribute["listType"]

                if listTypeRawValue != nil {
                    let listType = LEOInputParagraphType(rawValue: listTypeRawValue as! Int)
                    var listPrefixWidth: CGFloat = 0

                    if listType == .numberedList {
                        var listPrefixString = textString.substring(with: range).components(separatedBy: " ")[0]
                        listPrefixString.append(" ")
                        listPrefixWidth = NSString(string: listPrefixString).size(withAttributes: [NSAttributedString.Key.font: normalFont]).width
                    } else {
                        listPrefixWidth = NSString(string: "• ").size(withAttributes: [NSAttributedString.Key.font: normalFont]).width
                    }

                    let lineHeight = normalFont.lineHeight

                    var paragraphStyle: NSMutableParagraphStyle!

                    if defaultParagraphStyle != nil {
                        paragraphStyle = (defaultParagraphStyle!.mutableCopy() as! NSMutableParagraphStyle)
                    } else {
                        paragraphStyle = NSMutableParagraphStyle()
                    }

                    paragraphStyle.headIndent = listPrefixWidth + lineHeight
                    paragraphStyle.firstLineHeadIndent = lineHeight
                    mutableAttributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle!, NSAttributedString.Key.font: normalFont], range: range)
                }
            }
        }

        return mutableAttributedString
    }

    open class func attributesWithJSONString(_ jsonString: String) -> [[String: AnyObject]] {
        let jsonDict: [String: AnyObject] = try! JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String : AnyObject]

        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]

        return attributes
    }

    open class func jsonStringWithAttributesData(_ attributesData: [Dictionary<String, AnyObject>], text currentText: String) -> String {
        var jsonDict: [String: AnyObject] = [:]

        jsonDict["text"] = currentText as AnyObject?
        jsonDict["attributes"] = attributesData as AnyObject?

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        return String(data: jsonData, encoding: String.Encoding.utf8)!
    }

    open class func textWithJSONString(_ jsonString: String) -> String {
        let jsonDict: [String: AnyObject] = try! JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String : AnyObject]

        let textString = jsonDict["text"] as! String
        return textString
    }

    // MARK: Font and paragraph type estimate

    open func fontOfTypeWithAttribute(_ attribute: [String: AnyObject]) -> UIFont {
        let fontType = attribute["fontType"] as? String
        var currentFont = normalFont

        if fontType == "title" {
            currentFont = titleFont
        } else if fontType == "bold" {
            currentFont = boldFont
        } else if fontType == "italic" {
            currentFont = italicFont
        }

        return currentFont
    }

    open func currentParagraphType() -> LEOInputParagraphType {
        return nck_textStorage.currentParagraphTypeWithLocation(selectedRange.location)
    }

    open func inputModeWithIndex(_ index: Int) -> LEOInputFontMode {
        guard let currentFont = nck_textStorage.safeAttribute(NSAttributedString.Key.font.rawValue, atIndex: index, effectiveRange: nil, defaultValue: nil) as? UIFont else {
            return .normal
        }

        if currentFont.pointSize == titleFont.pointSize {
            return .title
        } else if LEOTextUtil.isBoldFont(currentFont, boldFontName: boldFont.fontName) {
            return .bold
        } else if LEOTextUtil.isItalicFont(currentFont, italicFontName: italicFont.fontName) {
            return .italic
        } else {
            return .normal
        }
    }

    // MARK: - Menu controller button actions

  @objc func boldButtonAction() {
        buttonActionWithInputFontMode(.bold)
    }

  @objc func italicButtonAction() {
        buttonActionWithInputFontMode(.italic)
    }

    func buttonActionWithInputFontMode(_ mode: LEOInputFontMode) {
        guard mode != .normal else {
            return
        }

        if LEOTextUtil.isSelectedTextWithTextView(self) {
            let currentFont = self.attributedText.safeAttribute(NSAttributedString.Key.font.rawValue, atIndex: selectedRange.location, effectiveRange: nil, defaultValue: normalFont) as! UIFont
            let compareFontName = (mode == .bold) ? boldFont.fontName : italicFont.fontName

            let isSpecialFont = (mode == .bold ? LEOTextUtil.isBoldFont(currentFont, boldFontName: compareFontName) : LEOTextUtil.isItalicFont(currentFont, italicFontName: compareFontName))

            if !isSpecialFont {
                changeSelectedTextWithInputFontMode(mode)
            } else {
                changeSelectedTextWithInputFontMode(.normal)
            }
        } else {
            inputFontMode = (inputFontMode != mode) ? mode : .normal
        }
    }

    // MARK: - Utils

    func podBundle() -> Bundle {
        let bundle = Bundle(path: Bundle(for: LEOTextView.self).path(forResource: "LEOTextView", ofType: "bundle")!)

        return bundle!
    }

    func mutableParargraphWithDefaultSetting() -> NSMutableParagraphStyle {
        var paragraphStyle: NSMutableParagraphStyle!

        if let defaultParagraphStyle = defaultAttributesForLoad[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
            paragraphStyle = (defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle)
        } else {
            paragraphStyle = NSMutableParagraphStyle()
        }

        return paragraphStyle
    }

    // MARK: - Cut & Copy & Paste support

    func preHandleWhenCutOrCopy() {
        let copyText = NSString(string: text).substring(with: selectedRange)

        currentAttributesDataWithPasteboard = textAttributesDataWithAttributedString(attributedText.attributedSubstring(from: selectedRange))

        if currentAttributesDataWithPasteboard != nil {
            UserDefaults.standard.setValue(LEOTextView.jsonStringWithAttributesData(currentAttributesDataWithPasteboard!, text: copyText), forKey: nck_attributesDataWithPasteboardUserDefaultKey)
        }
    }

    open override func cut(_ sender: Any?) {
        preHandleWhenCutOrCopy()

        super.cut(sender)
    }

    open override func copy(_ sender: Any?) {
        preHandleWhenCutOrCopy()

        super.copy(sender)
    }

    open override func paste(_ sender: Any?) {
        guard let pasteText = UIPasteboard.general.string else {
            return
        }
        let pasteLocation = selectedRange.location

        super.paste(sender)

        if currentAttributesDataWithPasteboard == nil {
            if let attributesDataJsonString = UserDefaults.standard.value(forKey: nck_attributesDataWithPasteboardUserDefaultKey) as? String {
                let jsonDict: [String: AnyObject] = try! JSONSerialization.jsonObject(with: attributesDataJsonString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String : AnyObject]
                let propertiesWithText = jsonDict["text"] as! String
                if propertiesWithText != pasteText {
                    return
                }

                currentAttributesDataWithPasteboard = LEOTextView.attributesWithJSONString(attributesDataJsonString)
            }
        }

        // Drawing properties about text
        currentAttributesDataWithPasteboard?.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range = NSRange(location: (attribute["location"] as! Int) + pasteLocation, length: attribute["length"] as! Int)

            if attributeName == NSAttributedString.Key.font.rawValue {
                let currentFont = fontOfTypeWithAttribute(attribute)

              self.nck_textStorage.safeAddAttributes([NSAttributedString.Key(rawValue: attributeName): currentFont], range: range)
            }
        }

        // Drawing paragraph by line head judgement
        var lineLocation = pasteLocation
        pasteText.enumerateLines { [unowned self] (line, stop) in
            let lineLength = line.length()

            if LEOTextUtil.markdownOrderedListRegularExpression.matches(in: line, options: .reportProgress, range: NSMakeRange(0, lineLength)).count > 0 ||
                       LEOTextUtil.markdownUnorderedListRegularExpression.matches(in: line, options: .reportProgress, range: NSMakeRange(0, lineLength)).count > 0 {
                let listPrefixString: NSString = NSString(string: line.components(separatedBy: " ")[0]).appending(" ") as NSString

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = listPrefixString.size(withAttributes: [NSAttributedString.Key.font: self.normalFont]).width + self.normalFont.lineHeight
                paragraphStyle.firstLineHeadIndent = self.normalFont.lineHeight

                self.nck_textStorage.safeAddAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSMakeRange(lineLocation, lineLength))
            }

            // Don't lose \n
            lineLocation += (lineLength + 1)
        }
    }
}
