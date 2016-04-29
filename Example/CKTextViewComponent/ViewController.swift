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
        
        ckTextView?.text = "Hello World"
        
        ckTextView?.textContainer.exclusionPaths.append(UIBezierPath(rect: CGRect(x: 0, y: 0, width: 200, height: 100)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func DrawTextButtonAction(sender: AnyObject) {
        ckTextView?.drawText()
    }
    

}

