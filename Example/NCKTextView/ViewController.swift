//
//  ViewController.swift
//  NCKTextView
//
//  Created by Chanricle King on 08/15/2016.
//  Copyright (c) 2016 Chanricle King. All rights reserved.
//

import UIKit
import NCKTextView

class ViewController: UIViewController, UITextViewDelegate {
    let textAttributesJSONKey = "textAttributesJSON"
    
    var textView: NCKTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "NCKTextView"
        
        // Init and config TextView
        textView = NCKTextView(frame: self.view.bounds, textContainer: NSTextContainer())
        textView.enableToolbar()
        textView.nck_delegate = self
        
        // add to View
        self.view.addSubview(textView)

        textView.becomeFirstResponder()
    }
    
    @IBAction func saveButtonAction(sender: AnyObject) {
        textView.resignFirstResponder()
        
        let textAttributesJSON = textView.textAttributesJSON()
        
        NSUserDefaults.standardUserDefaults().setValue(textAttributesJSON, forKey: textAttributesJSONKey)
        
        print("textAttributesJSON: \(textAttributesJSON)")
        
        alert("Current attributed text export to JSON string successed and saved.")
    }
    
    @IBAction func loadButtonAction(sender: AnyObject) {
        textView.resignFirstResponder()
        
        let textAttributesJSON = NSUserDefaults.standardUserDefaults().valueForKey(textAttributesJSONKey)
        
        let jsonDict: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(textAttributesJSON!.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as! [String : AnyObject]
        let text = jsonDict["text"] as! String
        
        let attributedString = NCKTextView.generateAttributedTextWithString(text, font: UIFont.systemFontOfSize(17), titleFont: UIFont.boldSystemFontOfSize(18), keepTitlePunctuation: true, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(17)])
        
        textView.beginSetAttributedText()
        textView.attributedText = attributedString
        textView.endSetAttributedText()
        
//        if textAttributesJSON != nil {
//            textView.setAttributeTextWithJSONString(textAttributesJSON as! String)
//        }
    }
    
    func alert(message: String) {
        let alertController = UIAlertController(title: "Saved", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChangeSelection(textView: UITextView) {
        
    }

}

