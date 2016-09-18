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
    
    @IBAction func saveButtonAction(_ sender: AnyObject) {
        textView.resignFirstResponder()
        
        let textAttributesJSON = textView.textAttributesJSON()
        
        UserDefaults.standard.setValue(textAttributesJSON, forKey: textAttributesJSONKey)
        
        print("textAttributesJSON: \(textAttributesJSON)")
        
        alert("Current attributed text export to JSON string successed and saved.")
    }
    
    @IBAction func loadButtonAction(_ sender: AnyObject) {
        textView.resignFirstResponder()
        
        let textAttributesJSON = UserDefaults.standard.value(forKey: textAttributesJSONKey)
        if textAttributesJSON != nil {
            textView.setAttributeTextWithJSONString(textAttributesJSON as! String)
        }
    }
    
    func alert(_ message: String) {
        let alertController = UIAlertController(title: "Saved", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        print("text view font: \(textView.font)")
    }

}

