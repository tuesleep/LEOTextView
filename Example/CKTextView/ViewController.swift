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
        ckTextView?.font = UIFont.init(name: "Helvetica", size: 17)
        ckTextView?.textAlignment
        
        self.containerView.addSubview(ckTextView!)
        
        ckTextView?.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Orientation changed
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) in
            self.ckTextView?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
            }) { (context) in
                self.ckTextView?.reloadText()
        }
    }
    
}

