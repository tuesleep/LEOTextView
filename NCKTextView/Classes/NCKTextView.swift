//
//  NCKTextView.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

public enum NCKInputFontMode {
    case Normal, Bold, Italic
}

public class NCKTextView: UITextView {
    // MARK: - Public properties
    
    public var inputFontMode: NCKInputFontMode = .Normal {
        didSet {
            // Change Button colors, keep bold and italic button color right.
            boldButton?.tintColor = toolbarButtonTintColor
            italicButton?.tintColor = toolbarButtonTintColor
            
            switch inputFontMode {
            case .Bold:
                boldButton?.tintColor = toolbarButtonHighlightColor
                break
            case .Italic:
                italicButton?.tintColor = toolbarButtonHighlightColor
                break
            default:
                break
            }
        }
    }
    
    public var toolbar: UIToolbar?
    public var toolbarHeight: CGFloat = 40
    public var currentFrame: CGRect = CGRectZero
    
    public var toolbarButtonTintColor: UIColor = UIColor.blackColor()
    public var toolbarButtonHighlightColor: UIColor = UIColor.orangeColor()
    
    // Custom fonts
    
    public var normalFont: UIFont = UIFont.systemFontOfSize(18) {
        didSet {
            self.font = normalFont
        }
    }
    
    public var boldFont: UIFont = UIFont.boldSystemFontOfSize(18)
    public var italicFont: UIFont = UIFont.italicSystemFontOfSize(18)
    
    // MARK: - UI Buttons
    
    var boldButton: UIBarButtonItem?
    var italicButton: UIBarButtonItem?
    
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
        currentFrame = self.frame
        
        customSelectionMenu()
    }
    
    // MARK: Public APIs
    
    public func changeSelectedTextWithInputFontMode(mode: NCKInputFontMode) {
        guard let nck_textStorage = self.textStorage as? NCKTextStorage else {
            return
        }
        
        nck_textStorage.performReplacementsForRange(selectedRange, mode: mode)
    }
    
    /**
        Enable the toolbar, binding the show and hide events.
     
     */
    public func enableToolbar() -> UIToolbar {
        toolbar = UIToolbar(frame: CGRect(origin: CGPoint(x: 0, y: CGRectGetHeight(UIScreen.mainScreen().bounds)), size: CGSize(width: CGRectGetWidth(UIScreen.mainScreen().bounds), height: toolbarHeight)))
        toolbar?.autoresizingMask = .FlexibleWidth
        toolbar?.backgroundColor = UIColor.clearColor()
        
        toolbar?.items = enableBarButtonItems()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        return toolbar!
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
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            
            if attributeName == NSFontAttributeName {
                if let currentFont = UIFont(name: attribute["fontName"] as! String, size: normalFont.pointSize) {
                    self.textStorage.addAttribute(NSFontAttributeName, value: currentFont, range: NSRange(location: attribute["location"] as! Int, length: attribute["length"] as! Int))
                }
            }
        }
    }
    
    // MARK: - Toolbar buttons
    
    func enableBarButtonItems() -> [UIBarButtonItem] {
        let bundle = NSBundle(path: NSBundle(forClass: NCKTextView.self).pathForResource("NCKTextView", ofType: "bundle")!)
        
        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(named: "icon-keyboard", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.hideKeyboardButtonAction))
        
        // Common function buttons
        boldButton = UIBarButtonItem(image: UIImage(named: "icon-bold", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.boldButtonAction))
        italicButton = UIBarButtonItem(image: UIImage(named: "icon-italic", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.italicButtonAction))
        let unorderedListButton = UIBarButtonItem(image: UIImage(named: "icon-unorderedlist", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.unorderedListButtonAction))
        let orderedListButton = UIBarButtonItem(image: UIImage(named: "icon-orderedlist", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.orderedListButtonAction))
        
        let buttonItems = [boldButton!, flexibleSpaceButton, italicButton!, flexibleSpaceButton, unorderedListButton, flexibleSpaceButton, orderedListButton, flexibleSpaceButton, hideKeyboardButton]
        
        // Button styles
        for buttonItem in buttonItems {
            buttonItem.tintColor = toolbarButtonTintColor
        }
        
        return buttonItems
    }
    
    func hideKeyboardButtonAction() {
        self.resignFirstResponder()
    }
    
    func buttonActionWithInputFontMode(mode: NCKInputFontMode) {
        guard mode != .Normal else {
            return
        }
        
        if NCKTextUtil.isSelectedTextWithTextView(self) {
            let currentFont = self.attributedText.attribute(NSFontAttributeName, atIndex: selectedRange.location, effectiveRange: nil) as! UIFont
            
            let isSpecialFont = (mode == .Bold ? NCKTextUtil.isBoldFont(currentFont) : NCKTextUtil.isItalicFont(currentFont))
            
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
        
        menuController.menuItems = [UIMenuItem(title: NSLocalizedString("Bold", comment: "Bold"), action: #selector(self.boldMenuItemAction)), UIMenuItem(title: NSLocalizedString("Italic", comment: "Italic"), action: #selector(self.italicMenuItemAction))]
    }
    
    func boldMenuItemAction() {
        boldButtonAction()
    }
    
    func italicMenuItemAction() {
        italicButtonAction()
    }
    
    func buttonActionWithOrderedOrUnordered(orderedList isOrderedList: Bool) {
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
            let listPrefix = (isOrderedList ? "1. " : "• ")
            
            self.textStorage.replaceCharactersInRange(NSRange(location: objectLineAndIndex.1, length: 0), withString: listPrefix)
            
            self.selectedRange = NSRange(location: self.selectedRange.location + NSString(string: listPrefix).length, length: self.selectedRange.length)
        }
    }
    
    func boldButtonAction() {
        buttonActionWithInputFontMode(.Bold)
    }
    
    func italicButtonAction() {
        buttonActionWithInputFontMode(.Italic)
    }
    
    func unorderedListButtonAction() {
        buttonActionWithOrderedOrUnordered(orderedList: false)
    }
    
    func orderedListButtonAction() {
        buttonActionWithOrderedOrUnordered(orderedList: true)
    }
    
    // MARK: - Other methods
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let duration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let keyboardEnd = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let toolbarHeight = toolbar!.frame.size.height
        
        if notification.name == UIKeyboardWillShowNotification {
            self.superview?.addSubview(toolbar!)
            
            var textViewFrame = self.frame
            textViewFrame.size.height = self.superview!.frame.height - keyboardEnd.height - toolbarHeight
            self.frame = textViewFrame
            
            UIView.animateWithDuration(duration, animations: {
                var frame = self.toolbar!.frame
                frame.origin.y = self.superview!.frame.height - (keyboardEnd.height + toolbarHeight)
                self.toolbar!.frame = frame
            }, completion: nil)
        } else {
            self.frame = currentFrame
            
            UIView.animateWithDuration(duration, animations: {
                var frame = self.toolbar!.frame
                frame.origin.y = self.superview!.frame.size.height
                self.toolbar!.frame = frame
                
            }, completion: { (success) in
                self.toolbar!.removeFromSuperview()
            })
        }
    }
}
