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
    
    public var inputFontMode: NCKInputFontMode = .Normal
    public var toolbar: UIToolbar?
    public var toolbarHeight: CGFloat = 40
    public var currentFrame: CGRect = CGRectZero
    
    public var toolbarButtonTintColor: UIColor = UIColor.blackColor()
    public var toolbarButtonHighlightColor: UIColor = UIColor.orangeColor()
    
    // Custom fonts
    
    public var normalFont: UIFont = UIFont(name: "Helvetica", size: 18)! {
        didSet {
            self.font = normalFont
        }
    }
    
    public var boldFont: UIFont = UIFont(name: "Helvetica-Bold", size: 18)!
    public var italicFont: UIFont = UIFont(name: "Helvetica-Oblique", size: 18)!
    
    var boldButton: UIBarButtonItem?
    var italicButton: UIBarButtonItem?
    
    // MARK: - Init methods
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        let layoutManager = NSLayoutManager()
        
        if textContainer != nil {
            layoutManager.addTextContainer(textContainer!)
        }
        
        let textStorage = NCKTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: textContainer)
        
        currentFrame = frame
        
        textStorage.textView = self
    }
    
    // MARK: Public APIs
    
    public func boldSelectedText() {
        var mutableAttributedText = self.attributedText.mutableCopy() as! NSMutableAttributedString
        mutableAttributedText.addAttribute(NSFontAttributeName, value: boldFont, range: selectedRange)
        
        
    }
    
    public func italicSelectedText() {
        self.textStorage.addAttribute(NSFontAttributeName, value: italicFont, range: selectedRange)
    }
    
    public func normalSelectedText() {
        self.textStorage.addAttribute(NSFontAttributeName, value: normalFont, range: selectedRange)
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
    
    func boldButtonAction() {
        if NCKTextUtil.isSelectedTextWithTextView(self) {
            boldSelectedText()
        } else {
            // Change Button colors, keep bold and italic button color right.
            italicButton?.tintColor = toolbarButtonTintColor
            
            if inputFontMode == .Bold {
                boldButton?.tintColor = toolbarButtonTintColor
                inputFontMode = .Normal
            } else {
                boldButton?.tintColor = toolbarButtonHighlightColor
                inputFontMode = .Bold
            }
        }
    }
    
    func italicButtonAction() {
        if NCKTextUtil.isSelectedTextWithTextView(self) {
            italicSelectedText()
        } else {
            // Change Button colors, keep bold and italic button color right.
            boldButton?.tintColor = toolbarButtonTintColor
            
            if inputFontMode == .Italic {
                italicButton?.tintColor = toolbarButtonTintColor
                inputFontMode = .Normal
            } else {
                italicButton?.tintColor = toolbarButtonHighlightColor
                inputFontMode = .Italic
            }
        }
    }
    
    func unorderedListButtonAction() {
        
    }
    
    func orderedListButtonAction() {
        
    }
    
    // MARK: - Other methods
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let duration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let curve = info[UIKeyboardAnimationCurveUserInfoKey] as! Int
        let keyboardEnd = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let toolbarHeight = toolbar!.frame.size.height

        let animationOptions = curve << 16
        
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
