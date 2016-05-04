//
//  ViewController.swift
//  CKTextView
//
//  Created by Chanricle King on 04/28/2016.
//  Copyright (c) 2016 Chanricle King. All rights reserved.
//

import UIKit
import CKTextView

class ViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    weak var ckTextView: CKTextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        ckTextView = CKTextView()
        
        ckTextView!.frame = self.containerView.bounds
        self.containerView.addSubview(ckTextView!)
        
        ckTextView?.text = "Hello World"
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func DrawTextButtonAction(sender: AnyObject) {
        ckTextView?.drawText()
        
        let pasteboard = UIPasteboard.generalPasteboard()
        
        for item in pasteboard.pasteboardTypes() {
            let itemData = pasteboard.dataForPasteboardType(item)
            
            print(itemData)
        }
        
        
    }
    
    
}

