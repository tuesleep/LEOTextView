//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

public class CKTextView: UITextView, UITextViewDelegate {

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initialized()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialized()
    }
    
    func initialized()
    {
        self.delegate = self
    }
    
    public func drawText()
    {
        
    }
    
    func drawNumberLabelWithRect(rect: CGRect, number: Int)
    {
        let numberBezierPath = UIBezierPath(rect: rect)
        let numberLabel = UILabel(frame: numberBezierPath.bounds)
        numberLabel.text = "\(number). "
        numberLabel.font = UIFont.systemFontOfSize(rect.size.height)
        
        // Append label and exclusion bezier path.
        self.addSubview(numberLabel)
        self.textContainer.exclusionPaths.append(numberBezierPath)
    }
    
    // MARK: UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        return true
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        
    }
    
    public func textViewDidChange(textView: UITextView)
    {
        let cursorLocation = textView.selectedRange.location;
        print("cursor location: \(cursorLocation)")
        
        print("text height: \(CKTextUtil.textHeightForTextView(textView))")
    }
    
    public override func paste(sender: AnyObject?) {
        print("textview paste invoke.")
    }

}
