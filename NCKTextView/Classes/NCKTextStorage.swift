//
//  NCKTextStorage.swift
//  Pods
//
//  Created by Chanricle King on 8/15/16.
//
//

class NCKTextStorage: NSTextStorage {

    var currentString: NSMutableAttributedString = NSMutableAttributedString()
    var attributes: Dictionary<String, AnyObject> = [:]
    
    // MARK: - Must override
    override var string: String {
        return currentString.string
    }
    
    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return currentString.attributesAtIndex(location, effectiveRange: range)
    }
    
    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()
        currentString.replaceCharactersInRange(range, withString: str)
        edited(.EditedCharacters, range: range, changeInLength: str.characters.count - range.length)
        endEditing()
    }
    
    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()
        currentString.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    // MARK: - Other overrided


}
