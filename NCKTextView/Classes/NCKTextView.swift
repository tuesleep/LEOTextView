//
//  NCKTextView.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

public enum NCKInputFontMode: Int {
    case Normal, Bold, Italic, Title
}

public enum NCKInputParagraphType: Int {
    case Title, Body, BulletedList, DashedList, NumberedList
}

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
    
    public var checkedListIconImage: UIImage?, checkedListCheckedIconImage: UIImage?
    
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
        delegate = self
        
        undoManager?.disableUndoRegistration()
        
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
    
    func customTextView() {
        customSelectionMenu()
    }
    
    func initBuiltInCheckedListImageIfNeeded() {
        if checkedListIconImage == nil || checkedListCheckedIconImage == nil {
            let bundle = podBundle()
            
            checkedListIconImage = UIImage(named: "icon-checkbox-normal", inBundle: bundle, compatibleWithTraitCollection: nil)
            checkedListCheckedIconImage = UIImage(named: "icon-checkbox-checked", inBundle: bundle, compatibleWithTraitCollection: nil)
        }
    }
    
    // MARK: Public APIs
    
    public func changeCurrentParagraphTextWithInputFontMode(mode: NCKInputFontMode) {
        let paragraphLocation = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location).1
        let nextLineBreakLocation = NCKTextUtil.lineEndIndexWithString(self.text, location: selectedRange.location)
        
        guard let nck_textStorage = self.textStorage as? NCKTextStorage else {
            return
        }
        
        nck_textStorage.performReplacementsForRange(NSRange(location: paragraphLocation, length: nextLineBreakLocation - paragraphLocation), mode: mode)
    }
    
    public func changeSelectedTextWithInputFontMode(mode: NCKInputFontMode) {
        guard let nck_textStorage = self.textStorage as? NCKTextStorage else {
            return
        }
        
        nck_textStorage.performReplacementsForRange(selectedRange, mode: mode)
    }
    
    /**
        All of attributes about current text by JSON
     */
    public func textAttributesJSON() -> String {
        var attributesData: [Dictionary<String, AnyObject>] = []
        
        self.attributedText.enumerateAttributesInRange(NSRange(location: 0, length: NSString(string: self.text).length), options: .Reverse) { (attr, range, mutablePointer) in
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
                // Handle checkedList icon saved.
                else if $0 == NSAttachmentAttributeName {
                    let textAttachment = attr[$0] as! NSTextAttachment
                    
                    // Now, only checkbox type.
                    attribute["attachmentType"] = "checkbox"
                    attribute["checked"] = (textAttachment.image == self.checkedListIconImage) ? 0 : 1
                    
                    attributesData.append(attribute)
                }
                // Paragraph indent saved
                else if $0 == NSParagraphStyleAttributeName {
                    let nck_textStorage = self.textStorage as! NCKTextStorage
                    let paragraphType = nck_textStorage.currentParagraphTypeWithLocation(range.location)
                    
                    if paragraphType == .BulletedList || paragraphType == .DashedList || paragraphType == .NumberedList {
                        attribute["listType"] = paragraphType.rawValue
                        attributesData.append(attribute)
                    }
                }
            }
        }
        
        var jsonDict: [String: AnyObject] = [:]
        
        jsonDict["text"] = self.text
        jsonDict["attributes"] = attributesData
        
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(jsonDict, options: .PrettyPrinted)
        return String(data: jsonData, encoding: NSUTF8StringEncoding)!
    }
    
    public func setAttributeTextWithJSONString(jsonString: String) {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        print(jsonDict)
        
        let text = jsonDict["text"] as! String
        self.attributedText = NSAttributedString(string: text, attributes: self.defaultAttributesForLoad)
        
        setAttributesWithJSONString(jsonString)
    }
    
    public func setAttributesWithJSONString(jsonString: String) {
        let attributes = NCKTextView.attributesWithJSONString(jsonString)
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)
            
            if attributeName == NSFontAttributeName {
                let currentFont = fontOfTypeWithAttribute(attribute)
                
                self.textStorage.addAttribute(attributeName, value: currentFont, range: range)
            } else if attributeName == NSAttachmentAttributeName {
                let attachmentType = attribute["attachmentType"] as! String
                
                if attachmentType == "checkbox" {
                    let checked = attribute["checked"] as! Int
                    let checkListAttachment = NSTextAttachment()
                    checkListAttachment.image = (checked == 0) ? checkedListIconImage! : checkedListCheckedIconImage!
                    self.textStorage.addAttribute(attributeName, value: checkListAttachment, range: range)
                }
            } else if attributeName == NSParagraphStyleAttributeName {
                let listType = NCKInputParagraphType(rawValue: attribute["listType"] as! Int)
                var listPrefixWidth: CGFloat = 0
                
                if listType == .NumberedList {
                    let textString = NSString(string: NCKTextView.textWithJSONString(jsonString))
                    var listPrefixString = textString.componentsSeparatedByString(" ")[0]
                    listPrefixString.appendContentsOf(" ")
                    listPrefixWidth = NSString(string: listPrefixString).sizeWithAttributes([NSFontAttributeName: normalFont]).width
                } else {
                    listPrefixWidth = NSString(string: "• ").sizeWithAttributes([NSFontAttributeName: normalFont]).width
                }
                
                let lineHeight = normalFont.lineHeight
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = listPrefixWidth + lineHeight
                paragraphStyle.firstLineHeadIndent = lineHeight
                self.textStorage.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: range)
            }
        }
    }
    
    public class func addAttributesWithAttributedString(attributedString: NSAttributedString, jsonString: String, normalFont: UIFont, titleFont: UIFont, boldFont: UIFont, italicFont: UIFont) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let attributes = NCKTextView.attributesWithJSONString(jsonString)
        let tool_nck_textView = NCKTextView(normalFont: normalFont, titleFont: titleFont, boldFont: boldFont, italicFont: italicFont)
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let range  = NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int)
            
            if attributeName == NSFontAttributeName {
                let currentFont = tool_nck_textView.fontOfTypeWithAttribute(attribute)
                
                mutableAttributedString.addAttribute(NSFontAttributeName, value: currentFont, range: range)
            } else if attributeName == NSAttachmentAttributeName {
                let attachmentType = attribute["attachmentType"] as! String
                
                if attachmentType == "checkbox" {
                    let checked = attribute["checked"] as! Int
                    let checkListTextAttachment = tool_nck_textView.checkListTextAttachmentWithChecked(checked == 1)
                    
                    mutableAttributedString.addAttribute(attributeName, value: checkListTextAttachment, range: range)
                }
            } else if attributeName == NSParagraphStyleAttributeName {
                let listType = NCKInputParagraphType(rawValue: attribute["listType"] as! Int)
                var listPrefixWidth: CGFloat = 0
                
                if listType == .NumberedList {
                    let textString = NSString(string: NCKTextView.textWithJSONString(jsonString))
                    var listPrefixString = textString.componentsSeparatedByString(" ")[0]
                    listPrefixString.appendContentsOf(" ")
                    listPrefixWidth = NSString(string: listPrefixString).sizeWithAttributes([NSFontAttributeName: normalFont]).width
                } else {
                    listPrefixWidth = NSString(string: "• ").sizeWithAttributes([NSFontAttributeName: normalFont]).width
                }
                
                let lineHeight = normalFont.lineHeight
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = listPrefixWidth + lineHeight
                paragraphStyle.firstLineHeadIndent = lineHeight
                mutableAttributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: range)
            }
        }
        
        return mutableAttributedString
    }
    
    public class func attributesWithJSONString(jsonString: String) -> [[String: AnyObject]] {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        return attributes
    }
    
    public class func textWithJSONString(jsonString: String) -> String {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let textString = jsonDict["text"] as! String
        return textString
    }
    
    public func fontOfTypeWithAttribute(attribute: [String: AnyObject]) -> UIFont {
        let fontType = attribute["fontType"] as? String
        var currentFont = self.normalFont
        
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
        guard let nck_textStorage = self.textStorage as? NCKTextStorage else {
            return .Body
        }
        
        return nck_textStorage.currentParagraphTypeWithLocation(selectedRange.location)
    }
    
    func buttonActionWithInputFontMode(mode: NCKInputFontMode) {
        guard mode != .Normal else {
            return
        }
        
        if NCKTextUtil.isSelectedTextWithTextView(self) {
            let currentFont = self.attributedText.attribute(NSFontAttributeName, atIndex: selectedRange.location, effectiveRange: nil) as! UIFont
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
    
    /**
        Create a new checklist string, a attributed string with icon image.
     */
    func checkListStringWithChecked(checked: Bool) -> NSAttributedString {
        let checkListTextAttachment = checkListTextAttachmentWithChecked(checked)
        let checkListString = NSAttributedString(attachment: checkListTextAttachment)
        
        return checkListString
    }
    
    func checkListTextAttachmentWithChecked(checked: Bool) -> NSTextAttachment {
        initBuiltInCheckedListImageIfNeeded()
        
        let checkListTextAttachment = NSTextAttachment()
        if checked {
            checkListTextAttachment.image = checkedListCheckedIconImage!
        } else {
            checkListTextAttachment.image = checkedListIconImage!
        }
        
        return checkListTextAttachment
    }
    
    func buttonActionWithOrderedOrUnordered(orderedList isOrderedList: Bool, listPrefix: String) {
        let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
        
        let objectLineRange = NSRange(location: 0, length: NSString(string: objectLineAndIndex.0).length)
        
        // Check current list type.
        let isCurrentOrderedList = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
        let isCurrentUnorderedList = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
        
        if (isCurrentOrderedList || isCurrentUnorderedList) {
            // Already list paragraph.
            let numberLength = NSString(string: objectLineAndIndex.0.componentsSeparatedByString(" ")[0]).length + 1
            
            let moveLocation = min(NSString(string: self.text).length - selectedRange.location, numberLength)
            
            self.textStorage.replaceCharactersInRange(NSRange(location: objectLineAndIndex.1, length: numberLength), withString: "")
            
            self.selectedRange = NSRange(location: selectedRange.location - moveLocation, length: selectedRange.length)
            
            // Handle head indent of paragraph.
            let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
            self.textStorage.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: paragraphRange)
        }

        if (isOrderedList && !isCurrentOrderedList) || (!isOrderedList && !isCurrentUnorderedList) {
            // Become list paragraph.
            self.textStorage.replaceCharactersInRange(NSRange(location: objectLineAndIndex.1, length: 0), withAttributedString: NSAttributedString(string: listPrefix, attributes: defaultAttributesForLoad))
            
            let listPrefixString = NSString(string: listPrefix)
            self.selectedRange = NSRange(location: self.selectedRange.location + listPrefixString.length, length: self.selectedRange.length)
            
            // Handle head indent of paragraph.
            let paragraphRange = NCKTextUtil.paragraphRangeOfString(self.text, location: selectedRange.location)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = listPrefixString.sizeWithAttributes([NSFontAttributeName: normalFont]).width + normalFont.lineHeight
            paragraphStyle.firstLineHeadIndent = normalFont.lineHeight
            self.textStorage.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: paragraphRange)
        }
    }
    
    func boldButtonAction() {
        buttonActionWithInputFontMode(.Bold)
    }
    
    func italicButtonAction() {
        buttonActionWithInputFontMode(.Italic)
    }
    
    func podBundle() -> NSBundle {
        let bundle = NSBundle(path: NSBundle(forClass: NCKTextView.self).pathForResource("NCKTextView", ofType: "bundle")!)
        
        return bundle!
    }
}
