//
//  ViewController.swift
//  NCKTextView
//
//  Created by Chanricle King on 08/15/2016.
//  Copyright (c) 2016 Chanricle King. All rights reserved.
//

import UIKit
import NCKTextView

class ViewController: UIViewController {
    
    var textView: NCKTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "NCKTextView"
        
        // Init and config TextView
        textView = NCKTextView(frame: self.view.bounds, textContainer: NSTextContainer())
        textView.enableToolbar()
        
        // add to View
        self.view.addSubview(textView)

        textView.becomeFirstResponder()
    }
    
    @IBAction func saveButtonAction(sender: AnyObject) {
        
    }
    
    @IBAction func loadButtonAction(sender: AnyObject) {
        
    }
}

