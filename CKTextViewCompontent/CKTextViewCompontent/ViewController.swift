//
//  ViewController.swift
//  CKTextViewCompontent
//
//  Created by Chanricle King on 16/4/27.
//  Copyright © 2016年 chanricle. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // TextView common style
        textView.layer.borderColor = UIColor.darkGrayColor().CGColor
        textView.layer.borderWidth = 1
        
        // handle text indent
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 38
        paragraphStyle.lineBreakMode = .ByClipping
        
        let lineOneString = NSAttributedString(string: "First, We have number one.\n",
                                               attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        
        let line2OneString = NSAttributedString(string: "Second, two.",
                                               attributes: [NSParagraphStyleAttributeName: paragraphStyle])
        
        let finalString = NSMutableAttributedString()
        finalString.appendAttributedString(lineOneString)
        finalString.appendAttributedString(line2OneString)
        
        textView.attributedText = finalString
        
        // The number label fill
        let numberLabel = UILabel()
        numberLabel.frame = CGRect(x: 38, y: 40 + 20, width: 15, height: 20)
        numberLabel.text = "1. "
        numberLabel.backgroundColor = UIColor.whiteColor()
        
        self.view.addSubview(numberLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

