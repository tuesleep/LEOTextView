//
//  ViewController.swift
//  CKTextViewComponent
//
//  Created by Chanricle King on 04/28/2016.
//  Copyright (c) 2016 Chanricle King. All rights reserved.
//

import UIKit
import CKTextViewComponent

class ViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    
    weak var ckTextView: CKTextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        ckTextView = CKTextView()
        
        ckTextView!.frame = self.containerView.bounds
        self.containerView.addSubview(ckTextView!)
        
        ckTextView?.text = "Hello World\nSecond"
        
        let numberBezierPath = UIBezierPath(rect: CGRect(x: 4, y: 8, width: 12, height: 10))
        let numberLabel = UILabel(frame: numberBezierPath.bounds)
        numberLabel.text = "1. "
        numberLabel.font = UIFont.systemFontOfSize(12)
        
        // Append label and exclusion bezier path.
        ckTextView?.addSubview(numberLabel)
        ckTextView?.textContainer.exclusionPaths.append(numberBezierPath)
        
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

