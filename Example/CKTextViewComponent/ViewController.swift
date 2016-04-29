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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let ckTextView = CKTextView()
        ckTextView.frame = self.view.bounds
        
        self.view.addSubview(ckTextView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

