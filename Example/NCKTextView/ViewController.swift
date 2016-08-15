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
        // Do any additional setup after loading the view, typically from a nib.
        
        textView = NCKTextView(frame: self.view.bounds, textContainer: NSTextContainer())
        self.view.addSubview(textView)
        
        textView.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

