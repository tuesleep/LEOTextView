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
    
    // MARK: - UI Buttons
    
    var formatButton: UIBarButtonItem?
    var boldButton: UIBarButtonItem?
    var italicButton: UIBarButtonItem?
    
    var nck_formatTableViewController: NCKFormatTableViewController?
    var formatMenuView: UIView?
    
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
        
        self.alwaysBounceVertical = true
        
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
        
        setAttributesWithJSONString(jsonString)
    }
    
    public func setAttributesWithJSONString(jsonString: String) {
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
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
    
    public class func addAttributesWithAttributedString(attributedString: NSAttributedString, jsonString: String, pointSize: CGFloat) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        
        let attributes = jsonDict["attributes"] as! [[String: AnyObject]]
        
        attributes.forEach {
            let attribute = $0
            let attributeName = attribute["name"] as! String
            
            if attributeName == NSFontAttributeName {
                if let currentFont = UIFont(name: attribute["fontName"] as! String, size: pointSize) {
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
    
    // MARK: - Toolbar buttons
    
    func enableBarButtonItems() -> [UIBarButtonItem] {
        let bundle = NSBundle(path: NSBundle(forClass: NCKTextView.self).pathForResource("NCKTextView", ofType: "bundle")!)
        
        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(named: "icon-keyboard", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.hideKeyboardButtonAction))
        
        formatButton = UIBarButtonItem(image: UIImage(named: "icon-format", inBundle: bundle, compatibleWithTraitCollection: nil), style: .Plain, target: self, action: #selector(self.formatButtonAction))
        
        let buttonItems = [formatButton!, flexibleSpaceButton, hideKeyboardButton]
        
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
                menuItems.append(UIMenuItem(title: NSLocalizedString("Bold", comment: "Bold"), action: #selector(self.boldMenuItemAction)))
                break
            case .Italic:
                menuItems.append(UIMenuItem(title: NSLocalizedString("Italic", comment: "Italic"), action: #selector(self.italicMenuItemAction)))
                break
            default:
                break
            }
        }
        
        menuController.menuItems = menuItems
    }
    
    func boldMenuItemAction() {
        boldButtonAction()
    }
    
    func italicMenuItemAction() {
        italicButtonAction()
    }
    
    func formatButtonAction() {
        if formatMenuView == nil {
            let bundle = NSBundle(path: NSBundle(forClass: NCKTextView.self).pathForResource("NCKTextView", ofType: "bundle")!)
            let nck_formatNavigationController = UIStoryboard(name: "NCKTextView", bundle: bundle).instantiateViewControllerWithIdentifier("NCKFormatNavigationController") as! UINavigationController
            
            nck_formatTableViewController = nck_formatNavigationController.viewControllers[0] as! NCKFormatTableViewController
            nck_formatTableViewController?.selectedCompletion = { [unowned self] (type) in
                let currentParagraphType = self.currentParagraphType()
                
                switch type {
                case .Title:
                    self.inputFontMode = .Title
                    self.changeCurrentParagraphTextWithInputFontMode(.Title)
                    
                    break
                case .Body:
                    self.inputFontMode = .Normal
                    if currentParagraphType == .Title {
                        self.changeCurrentParagraphTextWithInputFontMode(.Normal)
                    }
                    
                    break
                case .BulletedList:
                    self.buttonActionWithOrderedOrUnordered(orderedList: false, listPrefix: "• ")
                    break
                case .DashedList:
                    self.buttonActionWithOrderedOrUnordered(orderedList: false, listPrefix: "- ")
                    break
                case .NumberedList:
                    self.buttonActionWithOrderedOrUnordered(orderedList: true, listPrefix: "1. ")
                    break
                }
            }
            
            let superViewSize = self.superview!.bounds.size
            let toolbarOriginY = self.toolbar!.frame.origin.y
            let menuViewHeight: CGFloat = toolbarOriginY - 200 >= 44 ? 180 : 120
            
            nck_formatNavigationController.view.frame = CGRect(origin: CGPointZero, size: CGSize(width: superViewSize.width, height: menuViewHeight))
            
            formatMenuView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: toolbarOriginY + 44 - menuViewHeight), size: CGSize(width: superViewSize.width, height: menuViewHeight)))
            formatMenuView?.addSubview(nck_formatNavigationController.view)
            
            nck_formatTableViewController?.navigationItem.title = NSLocalizedString("Formatting", comment: "")
            nck_formatTableViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.formatMenuViewDoneButtonAction))
        }
        
        self.superview?.addSubview(formatMenuView!)
    }
    
    func formatMenuViewDoneButtonAction() {
        formatMenuView?.removeFromSuperview()
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
    
    // MARK: - Other methods
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let duration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let keyboardEnd = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let toolbarHeight = toolbar!.frame.size.height
        
        if notification.name == UIKeyboardWillShowNotification {
            formatMenuView?.removeFromSuperview()
            
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
