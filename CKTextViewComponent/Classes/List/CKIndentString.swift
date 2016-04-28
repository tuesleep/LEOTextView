//
//  CKIndentString.swift
//  Pods
//
//  Created by Chanricle King on 4/28/16.
//
//

import UIKit

enum HeadTextType {
    case Text, Number, Point
}

class CKIndentString: NSAttributedString
{
    // Mark left to indent text type.
    let headTextType: HeadTextType = .Text
    
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
