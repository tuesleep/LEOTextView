//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

class CKTextView: UITextView {

    let organizeStrings: Array<CKOrganizeString> = []
    
    func drawText()
    {
        var currentTextY: CGFloat;
        
        for attributedString in organizeStrings
        {
            let stringSize = attributedString.size()
            
            print(stringSize)
            
            switch attributedString.headTextType
            {
            case .Text:
                break
            case .Number:
                break
            case .Point:
                break
            }
            
        }
    }

}
