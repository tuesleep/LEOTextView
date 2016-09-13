//
//  NCKTextView.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

public class NCKTextView: UITextView {
    // MARK: - Public properties
    
    public var nck_delegate: UITextViewDelegate?
    
    public var inputFontMode: NCKInputFontMode = .Normal
    public var defaultAttributesForLoad: [String : AnyObject] = [:]
    public var selectMenuItems: [NCKInputFontMode] = [.Bold, .Italic]
    
    // Custom fonts
    public var normalFont: UIFont = UIFont.systemFontOfSize(17)
    public var titleFont: UIFont = UIFont.boldSystemFontOfSize(18)
    public var boldFont: UIFont = UIFont.boldSystemFontOfSize(17)
    public var italicFont: UIFont = UIFont.italicSystemFontOfSize(17)
    
    // MARK: - instance relations
    
    var nck_textStorage: NCKTextStorage!
    
    var currentAttributesDataWithPasteboard: [Dictionary<String, AnyObject>]?
    
    let nck_attributesDataWithPasteboardUserDefaultKey = "nck_attributesDataWithPasteboardUserDefaultKey"
    
    // MARK: - Init methods
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        let nonenullTextContainer = (textContainer == nil) ? NSTextContainer() : textContainer!
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(nonenullTextContainer)
        
        let textStorage = NCKTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: nonenullTextContainer)
        
        textStorage.textView = self
        
        // TextView property set
        delegate = self
        nck_textStorage = textStorage
        
        customTextView()
    }
    
    public init(normalFont: UIFont, titleFont: UIFont, boldFont: UIFont, italicFont: UIFont) {
        super.init(frame: CGRectZero, textContainer: NSTextContainer())
        
        self.font = normalFont
        self.normalFont = normalFont
        self.titleFont = titleFont
        self.boldFont = boldFont
        self.italicFont = italicFont
    }
    
    deinit {
        self.removeToolbarNotifications()
    }
    
    // MARK: - Custom text view
    
    func customTextView() {
        customSelectionMenu()
    }
    
    func customSelectionMenu() {
        let menuController = UIMenuController.sharedMenuController()
        var menuItems = [UIMenuItem]()
        
        selectMenuItems.forEach {
            switch $0 {
            case .Bold:
                menuItems.append(UIMenuItem(title: NSLocalizedString("Bold", comment: "Bold"), action: #selector(self.boldButtonAction)))
                break
            case .Italic:
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
    
    public func changeCurrentParagraphTextWithInputFontMode(mode: NCKInputFontMode) {
        let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
        let currentMode = inputModeWithIndex(paragraphRange.location)
        
        nck_textStorage.undoSupportChangeWithRange(paragraphRange, toMode: mode.rawValue, currentMode: currentMode.rawValue)
    }
    
    public func changeSelectedTextWithInputFontMode(mode: NCKInputFontMode) {
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
    func changeCurrentParagraphToOrderedList(orderedList isOrderedList: Bool, listPrefix: String) {
        // New method based on selectedRange text, and enumerate each line
        // Find target text
        var targetText: NSString!
        var targetRange: NSRange!
        
        let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
        let objectIndex = objectLineAndIndex.1
        
        if selectedRange.length == 0 {
            // current paragraph
            targetText = NCKTextUtil.currentParagraphStringOfString(text, location: selectedRange.location)
            targetRange = NSRange(location: objectIndex, length: targetText.length)
        } else {
            var lastIndex = selectedRange.location + selectedRange.length
            lastIndex = NCKTextUtil.lineEndIndexWithString(text, location: lastIndex)
            targetRange = NSRange(location: objectIndex, length: lastIndex - objectIndex)
            targetText = NSString(string: text).substringWithRange(targetRange)
        }
        
        // Confirm current is To list or To body by first line
        let objectLineRange = NSRange(location: 0, length: targetText.length)
        
        let isCurrentOrderedList = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(String(targetText), options: [], range: objectLineRange).count > 0
        let isCurrentUnorderedList = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(String(targetText), options: [], range: objectLineRange).count > 0
        
        let isListNow = (isCurrentOrderedList || isCurrentUnorderedList)
        let isTransformToList = (isOrderedList && !isCurrentOrderedList) || (!isOrderedList && !isCurrentUnorderedList)
        
        var numberedIndex = 1
        var replacedContents: [NSString] = []
        // enumerate each line
        targetText.enumerateLinesUsingBlock { (line, stop) in
            var currentLine: NSString = line
            
            // Clear old list characters if exist
            if NCKTextUtil.isListParagraph(line) {
                currentLine = currentLine.substringFromIndex(currentLine.rangeOfString(" ").location + 1)
            }
            
            // Appending new list characters if needed
            if isTransformToList {
                if isOrderedList {
                    currentLine = NSString(string: "\(numberedIndex). ").stringByAppendingString(String(currentLine))
                    numberedIndex += 1
                } else {
                    currentLine = NSString(string: listPrefix).stringByAppendingString(String(currentLine))
                }
            }
            
            replacedContents.append(currentLine)
        }
        
        let replacedContent = NSArray(array: replacedContents).componentsJoinedByString("\n")
        
        // Replace paragraph
        nck_textStorage.undoSupportReplaceRange(targetRange, withAttributedString: NSAttributedString(string: replacedContent, attributes: defaultAttributesForLoad), oldAttributedString: NSAttributedString(string: String(targetText), attributes: defaultAttributesForLoad), selectedRangeLocationMove: replacedContent.length() - targetText.length)
        
        if isListNow {
            // Already list paragraph.
            let listPrefixString: NSString = NSString(string: objectLineAndIndex.0.componentsSeparatedByString(" ")[0]).stringByAppendingString(" ")
            let listPrefixLength = listPrefixString.length
            
            // Handle head indent of paragraph.
            nck_textStorage.undoSupportResetIndenationRange(NSMakeRange(targetRange.location, replacedContent.length()), headIndent: listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width)
        }
        
        if isTransformToList {
            // Become list paragraph.
            let listPrefixString = NSString(string: listPrefix)
            
            // Handle head indent of paragraph.
            nck_textStorage.undoSupportMadeIndenationRange(NSMakeRange(targetRange.location, replacedContent.length()), headIndent: listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width)
        }
        
        /*
         
         let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
         
         let objectLineRange = NSRange(location: 0, length: NSString(string: objectLineAndIndex.0).length)
         
         // Check current list type.
         let isCurrentOrderedList = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
         let isCurrentUnorderedList = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
         
         let isListNow = (isCurrentOrderedList || isCurrentUnorderedList)
         let isTransformToList = (isOrderedList && !isCurrentOrderedList) || (!isOrderedList && !isCurrentUnorderedList)
         
         if isListNow {
         // Already list paragraph.
         let listPrefixString: NSString = NSString(string: objectLineAndIndex.0.componentsSeparatedByString(" ")[0]).stringByAppendingString(" ")
         let listPrefixLength = listPrefixString.length
         let moveLocation = min(NSString(string: self.text).length - selectedRange.location, listPrefixLength)
         
         // Handle head indent of paragraph.
         let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
         nck_textStorage.undoSupportResetIndenationRange(paragraphRange, headIndent: listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width)
         
         nck_textStorage.undoSupportReplaceRange(NSRange(location: objectLineAndIndex.1, length: listPrefixLength), withAttributedString: NSAttributedString(string: String(listPrefixString)), selectedRangeLocationMove: -moveLocation)
         }
         
         if isTransformToList {
         // Become list paragraph.
         let listPrefixString = NSString(string: listPrefix)
         
         nck_textStorage.undoSupportAppendRange(NSRange(location: objectLineAndIndex.1, length: 0), withAttributedString: NSAttributedString(string: listPrefix, attributes: defaultAttributesForLoad), selectedRangeLocationMove: listPrefixString.length)
         
         // Handle head indent of paragraph.
         let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
         nck_textStorage.undoSupportMadeIndenationRange(paragraphRange, headIndent: listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width)
         }
         
         */
    }
    
    // MARK: About text attributes and JSON
    
    public func textAttributesDataWithAttributedString(attributedString: NSAttributedString) -> [Dictionary<String, AnyObject>] {
        var attributesData: [Dictionary<String, AnyObject>] = []
        
        attributedString.enumerateAttributesInRange(NSRange(location: 0, length: attributedString.string.length()), options: .Reverse) { (attr, range, mutablePointer) in
            attr.keys.forEach {
                var attribute = [String: AnyObject]()
                
                // Common name property
                attribute["name"] = $0
                // Common range property
                attribute["location"] = range.location
                attribute["length"] = range.length
                
                if $0 == NSFontAttributeName {
                    let currentFont = attr[$0] as! UIFont
                    
                    var fontType = "normal";
                    
                    if (currentFont.pointSize == self.titleFont.pointSize) {
                        fontType = "title"
                    } else if (NCKTextUtil.isBoldFont(currentFont, boldFontName: self.boldFont.fontName)) {
                        fontType = "bold"
                    } else if (NCKTextUtil.isItalicFont(currentFont, italicFontName: self.italicFont.fontName)) {
                        fontType = "italic"
                    }
                    
                    // Normal font properties saved.
                    attribute["fontType"] = fontType
                    
                    attributesData.append(attribute)
                }
                // Paragraph indent saved
                else if $0 == NSParagraphStyleAttributeName {
                    let paragraphType = self.nck_textStorage.currentParagraphTypeWithLocation(range.location)
                    
                    if paragraphType == .BulletedList || paragraphType == .DashedList || paragraphType == .NumberedList {
                        attribute["listType"] = paragraphType.rawValue
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
    public func textAttributesJSON() -> String {
        let attributesData: [Dictionary<String, AnyObject>] = textAttributesDataWithAttributedString(attributedText)
        
        return NCKTextView.jsonStringWithAttributesData(attributesData, text: text)
    }
    
    public func setAttributeTextWithJSONString(jsonString: String) {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let text = jsonDict["text"] as! String
        self.attributedText = NSAttributedString(string: text, attributes: self.defaultAttributesForLoad)
        
        setAttributesWithJSONString(jsonString)
    }
    
    public func setAttributesWithJSONString(jsonString: String) {
        let attributes = NCKTextView.attributesWithJSONString(jsonString)
        let textString = NSString(string: NCKTextView.textWithJSONString(jsonString))
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)
            
            if attributeName == NSFontAttributeName {
                let currentFont = fontOfTypeWithAttribute(attribute)
                textStorage.addAttribute(attributeName, value: currentFont, range: range)
            } else if attributeName == NSParagraphStyleAttributeName {
                let listTypeRawValue = attribute["listType"]
                
                if listTypeRawValue != nil {
                    let listType = NCKInputParagraphType(rawValue: listTypeRawValue as! Int)
                    var listPrefixWidth: CGFloat = 0
                    
                    if listType == .NumberedList {
                        var listPrefixString = textString.substringWithRange(range).componentsSeparatedByString(" ")[0]
                        listPrefixString.appendContentsOf(" ")
                        listPrefixWidth = NSString(string: listPrefixString).sizeWithAttributes([NSFontAttributeName: normalFont]).width
                    } else {
                        listPrefixWidth = NSString(string: "• ").sizeWithAttributes([NSFontAttributeName: normalFont]).width
                    }
                    
                    let lineHeight = normalFont.lineHeight
                    
                    let paragraphStyle = mutableParargraphWithDefaultSetting()
                    paragraphStyle.headIndent = listPrefixWidth + lineHeight
                    paragraphStyle.firstLineHeadIndent = lineHeight
                    textStorage.addAttributes([NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: normalFont], range: range)
                }
            }
        }
    }
    
    public class func addAttributesWithAttributedString(attributedString: NSAttributedString, jsonString: String, normalFont: UIFont, titleFont: UIFont, boldFont: UIFont, italicFont: UIFont, defaultParagraphStyle: NSParagraphStyle?) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let attributes = NCKTextView.attributesWithJSONString(jsonString)
        let textString = NSString(string: NCKTextView.textWithJSONString(jsonString))
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range  = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)
            
            if attributeName == NSFontAttributeName {
                let fontType = attribute["fontType"] as? String
                var currentFont = normalFont
                
                if fontType == "title" {
                    currentFont = titleFont
                } else if fontType == "bold" {
                    currentFont = boldFont
                } else if fontType == "italic" {
                    currentFont = italicFont
                }
                
                mutableAttributedString.addAttribute(NSFontAttributeName, value: currentFont, range: range)
            } else if attributeName == NSParagraphStyleAttributeName {
                let listTypeRawValue = attribute["listType"]

                if listTypeRawValue != nil {
                    let listType = NCKInputParagraphType(rawValue: listTypeRawValue as! Int)
                    var listPrefixWidth: CGFloat = 0
                    
                    if listType == .NumberedList {
                        var listPrefixString = textString.substringWithRange(range).componentsSeparatedByString(" ")[0]
                        listPrefixString.appendContentsOf(" ")
                        listPrefixWidth = NSString(string: listPrefixString).sizeWithAttributes([NSFontAttributeName: normalFont]).width
                    } else {
                        listPrefixWidth = NSString(string: "• ").sizeWithAttributes([NSFontAttributeName: normalFont]).width
                    }
                    
                    let lineHeight = normalFont.lineHeight
                    
                    var paragraphStyle: NSMutableParagraphStyle!
                    
                    if defaultParagraphStyle != nil {
                        paragraphStyle = defaultParagraphStyle!.mutableCopy() as! NSMutableParagraphStyle
                    } else {
                        paragraphStyle = NSMutableParagraphStyle()
                    }
                    
                    paragraphStyle.headIndent = listPrefixWidth + lineHeight
                    paragraphStyle.firstLineHeadIndent = lineHeight
                    mutableAttributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: normalFont], range: range)
                }
            }
        }
        
        return mutableAttributedString
    }
    
    public class func attributesWithJSONString(jsonString: String) -> [[String: AnyObject]] {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        return attributes
    }
    
    public class func jsonStringWithAttributesData(attributesData: [Dictionary<String, AnyObject>], text currentText: String) -> String {
        var jsonDict: [String: AnyObject] = [:]
        
        jsonDict["text"] = currentText
        jsonDict["attributes"] = attributesData
        
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(jsonDict, options: .PrettyPrinted)
        return String(data: jsonData, encoding: NSUTF8StringEncoding)!
    }
    
    public class func textWithJSONString(jsonString: String) -> String {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let textString = jsonDict["text"] as! String
        return textString
    }
    
    // MARK: Font and paragraph type estimate
    
    public func fontOfTypeWithAttribute(attribute: [String: AnyObject]) -> UIFont {
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
    
    public func currentParagraphType() -> NCKInputParagraphType {
        return nck_textStorage.currentParagraphTypeWithLocation(selectedRange.location)
    }
    
    public func inputModeWithIndex(index: Int) -> NCKInputFontMode {
        guard let currentFont = nck_textStorage.safeAttribute(NSFontAttributeName, atIndex: index, effectiveRange: nil, defaultValue: nil) as? UIFont else {
            return .Normal
        }
        
        if currentFont.pointSize == titleFont.pointSize {
            return .Title
        } else if NCKTextUtil.isBoldFont(currentFont, boldFontName: boldFont.fontName) {
            return .Bold
        } else if NCKTextUtil.isItalicFont(currentFont, italicFontName: italicFont.fontName) {
            return .Italic
        } else {
            return .Normal
        }
    }
    
    // MARK: - Menu controller button actions
    
    func boldButtonAction() {
        buttonActionWithInputFontMode(.Bold)
    }
    
    func italicButtonAction() {
        buttonActionWithInputFontMode(.Italic)
    }
    
    func buttonActionWithInputFontMode(mode: NCKInputFontMode) {
        guard mode != .Normal else {
            return
        }
        
        if NCKTextUtil.isSelectedTextWithTextView(self) {
            let currentFont = self.attributedText.safeAttribute(NSFontAttributeName, atIndex: selectedRange.location, effectiveRange: nil, defaultValue: normalFont) as! UIFont
            let compareFontName = (mode == .Bold) ? boldFont.fontName : italicFont.fontName
            
            let isSpecialFont = (mode == .Bold ? NCKTextUtil.isBoldFont(currentFont, boldFontName: compareFontName) : NCKTextUtil.isItalicFont(currentFont, italicFontName: compareFontName))
            
            if !isSpecialFont {
                changeSelectedTextWithInputFontMode(mode)
            } else {
                changeSelectedTextWithInputFontMode(.Normal)
            }
        } else {
            inputFontMode = (inputFontMode != mode) ? mode : .Normal
        }
    }
    
    // MARK: - Utils
    
    func podBundle() -> NSBundle {
        let bundle = NSBundle(path: NSBundle(forClass: NCKTextView.self).pathForResource("NCKTextView", ofType: "bundle")!)
        
        return bundle!
    }
    
    func mutableParargraphWithDefaultSetting() -> NSMutableParagraphStyle {
        var paragraphStyle: NSMutableParagraphStyle!
        
        if let defaultParagraphStyle = defaultAttributesForLoad[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            paragraphStyle = defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
        } else {
            paragraphStyle = NSMutableParagraphStyle()
        }
        
        return paragraphStyle
    }
    
    // MARK: - Cut & Copy & Paste support
    
    func preHandleWhenCutOrCopy() {
        let copyText = NSString(string: text).substringWithRange(selectedRange)
        
        currentAttributesDataWithPasteboard = textAttributesDataWithAttributedString(attributedText.attributedSubstringFromRange(selectedRange))
        
        if currentAttributesDataWithPasteboard != nil {
            NSUserDefaults.standardUserDefaults().setValue(NCKTextView.jsonStringWithAttributesData(currentAttributesDataWithPasteboard!, text: copyText), forKey: nck_attributesDataWithPasteboardUserDefaultKey)
        }
    }
    
    public override func cut(sender: AnyObject?) {
        preHandleWhenCutOrCopy()
        
        super.cut(sender)
    }
    
    public override func copy(sender: AnyObject?) {
        preHandleWhenCutOrCopy()
        
        super.copy(sender)
    }
    
    public override func paste(sender: AnyObject?) {
        guard let pasteText = UIPasteboard.generalPasteboard().string else {
            return
        }
        let pasteLocation = selectedRange.location
        
        super.paste(sender)
        
        if currentAttributesDataWithPasteboard == nil {
            if let attributesDataJsonString = NSUserDefaults.standardUserDefaults().valueForKey(nck_attributesDataWithPasteboardUserDefaultKey) as? String {
                let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(attributesDataJsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
                let propertiesWithText = jsonDict["text"] as! String
                if propertiesWithText != pasteText {
                    return
                }
                
                currentAttributesDataWithPasteboard = NCKTextView.attributesWithJSONString(attributesDataJsonString)
            }
        }
        
        // Drawing properties about text
        currentAttributesDataWithPasteboard?.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range = NSRange(location: (attribute["location"] as! Int) + pasteLocation, length: attribute["length"] as! Int)
            
            if attributeName == NSFontAttributeName {
                let currentFont = fontOfTypeWithAttribute(attribute)
                
                self.nck_textStorage.safeAddAttributes([attributeName: currentFont], range: range)
            }
        }
        
        // Drawing paragraph by line head judgement
        var lineLocation = pasteLocation
        pasteText.enumerateLines { [unowned self] (line, stop) in
            let lineLength = line.length()
            
            if NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(line, options: .ReportProgress, range: NSMakeRange(0, lineLength)).count > 0 ||
                NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(line, options: .ReportProgress, range: NSMakeRange(0, lineLength)).count > 0 {
                let listPrefixString: NSString = NSString(string: line.componentsSeparatedByString(" ")[0]).stringByAppendingString(" ")
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = listPrefixString.sizeWithAttributes([NSFontAttributeName: self.normalFont]).width + self.normalFont.lineHeight
                paragraphStyle.firstLineHeadIndent = self.normalFont.lineHeight
                
                self.nck_textStorage.safeAddAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(lineLocation, lineLength + 1))
            }
            
            // Don't lose \n
            lineLocation += (lineLength + 1)
        }
    }
    
}
