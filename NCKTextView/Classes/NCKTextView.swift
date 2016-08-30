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
    
    public var inputFontMode: NCKInputFontMode = .Normal
    public var defaultAttributesForLoad: [String : AnyObject] = [:]
    public var selectMenuItems: [NCKInputFontMode] = [.Bold, .Italic]
    
    // Custom fonts
    
    public var normalFont: UIFont = UIFont.systemFontOfSize(18) {
        didSet {
            self.font = normalFont
        }
    }
    
    public var titleFont: UIFont = UIFont.boldSystemFontOfSize(20)
    public var boldFont: UIFont = UIFont.boldSystemFontOfSize(18)
    public var italicFont: UIFont = UIFont.italicSystemFontOfSize(18)
    
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
        
        customTextView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func customTextView() {
        self.font = normalFont

        customSelectionMenu()
    }
    
    // MARK: Public APIs
    
    public func changeCurrentParagraphTextWithInputFontMode(mode: NCKInputFontMode) {
        let paragraphLocation = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location).1
        let remainText: NSString = NSString(string: self.text).substringFromIndex(selectedRange.location)
        var nextLineBreakLocation = remainText.rangeOfString("\n").location
        nextLineBreakLocation = (nextLineBreakLocation == NSNotFound) ? NSString(string: self.text).length : nextLineBreakLocation + selectedRange.location
        
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
            
            var attribute = [String: AnyObject]()
            
            attr.keys.forEach {
                if $0 == NSFontAttributeName {
                    let currentFont = attr[$0] as! UIFont
                    
                    attribute["name"] = NSFontAttributeName
                    attribute["fontName"] = currentFont.fontName
                    attribute["location"] = range.location
                    attribute["length"] = range.length
                    attribute["isTitle"] = currentFont.pointSize == self.titleFont.pointSize ? 1 : 0
                    
                    attributesData.append(attribute)
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
        
        let text = jsonDict["text"] as! String
        self.text = text
        
        setAttributesWithJSONString(jsonString)
    }
    
    public func setAttributesWithJSONString(jsonString: String) {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let isTitle = attribute["isTitle"] as? Int
            
            if attributeName == NSFontAttributeName {
                let pointSize = (isTitle == 1) ? self.titleFont.pointSize : self.normalFont.pointSize
                
                if let currentFont = UIFont(name: attribute["fontName"] as! String, size: pointSize) {
                    self.textStorage.addAttribute(NSFontAttributeName, value: currentFont, range: NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int))
                }
            }
        }
    }
    
    public class func addAttributesWithAttributedString(attributedString: NSAttributedString, jsonString: String, pointSize: CGFloat) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            let isTitle = attribute["isTitle"] as? Int
            
            let nck_pointSize = (isTitle == 1) ? (pointSize + 2) : pointSize
            
            if attributeName == NSFontAttributeName {
                if let currentFont = UIFont(name: attribute["fontName"] as! String, size: nck_pointSize) {
                    mutableAttributedString.addAttribute(NSFontAttributeName, value: currentFont, range: NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int))
                }
            }
        }
        
        return mutableAttributedString
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
            
            var isSpecialFont = currentFont.fontName == compareFontName
            
            if !isSpecialFont {
                isSpecialFont = (mode == .Bold ? NCKTextUtil.isBoldFont(currentFont) : NCKTextUtil.isItalicFont(currentFont))
            }
            
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
    
    func buttonActionWithOrderedOrUnordered(orderedList isOrderedList: Bool, listPrefix: String) {
        let objectLineAndIndex = NCKTextUtil.objectLineAndIndexWithString(self.text, location: selectedRange.location)
        
        let objectLineRange = NSRange(location: 0, length: NSString(string: objectLineAndIndex.0).length)
        
        // Check current list type.
        let isCurrentOrderedList = NCKTextUtil.markdownOrderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
        let isCurrentUnorderedList = NCKTextUtil.markdownUnorderedListRegularExpression.matchesInString(objectLineAndIndex.0, options: [], range: objectLineRange).count > 0
        
        if (isCurrentOrderedList || isCurrentUnorderedList) {
            // Already orderedList
            let numberLength = NSString(string: objectLineAndIndex.0.componentsSeparatedByString(" ")[0]).length + 1
            
            let moveLocation = min(NSString(string: self.text).length - selectedRange.location, numberLength)
            
            self.textStorage.replaceCharactersInRange(NSRange(location: objectLineAndIndex.1, length: numberLength), withString: "")
            
            self.selectedRange = NSRange(location: self.selectedRange.location - moveLocation, length: self.selectedRange.length)
        }

        if (isOrderedList && !isCurrentOrderedList) || (!isOrderedList && !isCurrentUnorderedList) {
            self.textStorage.replaceCharactersInRange(NSRange(location: objectLineAndIndex.1, length: 0), withAttributedString: NSAttributedString(string: listPrefix, attributes: defaultAttributesForLoad))
            
            self.selectedRange = NSRange(location: self.selectedRange.location + NSString(string: listPrefix).length, length: self.selectedRange.length)
        }
    }
    
    func boldButtonAction() {
        buttonActionWithInputFontMode(.Bold)
    }
    
    func italicButtonAction() {
        buttonActionWithInputFontMode(.Italic)
    }
}
