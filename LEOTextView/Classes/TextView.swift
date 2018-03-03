//
//  TextView.swift
//  BulletedListTextView
//
//  Created by Wojtek on 25/02/2018.
//  Copyright © 2018 Wojtek. All rights reserved.
//

import Foundation
import UIKit
import LEOTextView

class TextView {
    
    func textViewConfig(frame: CGRect, textViewDelegate: UITextViewDelegate) -> LEOTextView {
        textView = LEOTextView(frame: frame, textContainer: NSTextContainer())
        _ = textView.enableToolbar()
        textView.nck_delegate = textViewDelegate
        return textView
    }
    
    func checkIfCircleWasTapped(sender: UITapGestureRecognizer) -> String {
        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager
        
        
        
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainerInset.left;
        location.y -= myTextView.textContainerInset.top;
        
        
        characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        print(characterIndex)
        
        if characterIndex < myTextView.textStorage.length {
            
            let myRange = NSRange(location: characterIndex, length: 1)
            substring = (myTextView.attributedText.string as NSString).substring(with: myRange)
            
            let attributeName = "MyCustomAttributeName"
            let attributeValue = myTextView.attributedText.attribute(NSAttributedStringKey(rawValue: attributeName), at: characterIndex, effectiveRange: nil) as? String
            if let value = attributeValue {
                print("You tapped on \(attributeName) and the value is: \(value)")
            }
            
        }
        return substring
    }
    
    func save() {
        textView.resignFirstResponder()
        
        let textAttributesJSON = textView.textAttributesJSON()
        
        UserDefaults.standard.setValue(textAttributesJSON, forKey: textAttributesJSONKey)
        
        print("textAttributesJSON: \(textAttributesJSON)")
    }
    
    func alert(_ message: String) -> UIAlertController {
        let alertController = UIAlertController(title: "Saved", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        return alertController
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        print("text view font: \(textView.font!.fontName)")
    }
    
    
    func load() {
        textView.resignFirstResponder()
        
        let textAttributesJSON = UserDefaults.standard.value(forKey: textAttributesJSONKey)
        if textAttributesJSON != nil {
            textView.setAttributeTextWithJSONString(textAttributesJSON as! String)
        }
    }
    
    
    func substringChange(point: String) {
        
        let mut = NSMutableAttributedString(attributedString: textView.attributedText)
        let attributes = mut.attributes(at: characterIndex, longestEffectiveRange: nil, in: NSRange(location: characterIndex, length: 1))
        
        mut.replaceCharacters(in: NSMakeRange(characterIndex, 1), with: NSAttributedString(string: point, attributes: attributes))
        textView.attributedText = mut
    }
}
