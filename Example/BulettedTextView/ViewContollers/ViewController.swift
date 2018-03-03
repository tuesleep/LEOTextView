//
//  ViewController.swift
//  BulletedListTextView
//
//  Created by Wojtek on 25/02/2018.
//  Copyright © 2018 Wojtek. All rights reserved.
//


import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textView = TextView().textViewConfig(frame: self.view.bounds, textViewDelegate: self)
        textView.delegate = self
        
        self.title = navigationBarTitle
        self.view.addSubview(textView)
        textView.becomeFirstResponder()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        textView.addGestureRecognizer(tap)
    }
    
    
    @IBAction func saveButtonAction(_ sender: AnyObject) {
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func loadButtonAction(_ sender: AnyObject) {
        TextView().load()
    }
    
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let substring = TextView().checkIfCircleWasTapped(sender: sender)
        print(substring)
        
        if(substring=="◯") {
            TextView().substringChange(point: "◉")
        } else if(substring=="◉") {
            TextView().substringChange(point: "◯")
        }
    }
}
