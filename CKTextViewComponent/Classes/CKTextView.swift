//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

public class CKTextView: UITextView, UITextViewDelegate {

    let organizeStrings: Array<CKOrganizeString> = []
    
    // Current time receive text
    var currentOrgaizeString: CKOrganizeString?
    
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
//        var currentTextY: CGFloat;
        
        for attributedString in organizeStrings
        {
            let stringSize = attributedString.size()
            
            print(stringSize)
            
            switch attributedString.headTextType
            {
            case .Text:
                break
            case .Number:
                break
            case .Point:
                break
            }
            
        }
    }
    
    // MARK: UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
//        if (currentOrgaizeString == nil) {
//            currentOrgaizeString = CKOrganizeString(string: "", indent: 0)
//            currentOrgaizeString?.headTextType = .Text
//        }
//        
//        currentOrgaizeString?.mutableString.appendString(text)
//        
//        if CKTextChecker.isReturn(text) {
//            
//        }
        
        return true
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        
    }
    
    public override func paste(sender: AnyObject?) {
        print("textview paste invoke.")
    }

}
