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
        
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidAppear(animated: Bool) {
        ckTextView = CKTextView.ck_textView(self.containerView.bounds)
        ckTextView?.font = UIFont.init(name: "Helvetica", size: 22)
        
        self.containerView.addSubview(ckTextView!)
        
        // Set text
        ckTextView?.ck_setText("1. helloworld,yeah,yes,more,helloworld,yeah,google,yeah,google.yeah,yes,oh\n2. world")
        
//        print("ck_text: \(ckTextView?.ck_text)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) in
            self.ckTextView?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
            }) { (context) in
                
        }
    }
    
    @IBAction func styleButtonAction(sender: UIBarButtonItem) {
        ckTextView?.ck_setText("1. helloworld,yeah,yes,more,helloworld,yeah,google,yeah,google.yeah,yes,oh\n2. world")
    }
    
}

