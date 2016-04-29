//
//  CKOrganizeString.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

enum HeadTextType {
    case Text, Number, Point
}

class CKOrganizeString: NSAttributedString {
    // Mark left to indent text type.
    var headTextType: HeadTextType = .Text
    
    init(string: String!, indent: CGFloat)
    {
        // handle text indent.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = indent
        paragraphStyle.lineBreakMode = .ByClipping
        
        // TODO: add \n to tail.
        
        super.init(string: string, attributes: [NSParagraphStyleAttributeName: paragraphStyle])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
