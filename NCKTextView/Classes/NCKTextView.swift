//
//  NCKTextView.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

public class NCKTextView: UITextView {
    
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
    }
    
}
