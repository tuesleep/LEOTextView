//
//  CKTextContainer.swift
//  Pods
//
//  Created by Chanricle King on 5/15/16.
//
//

import UIKit

public class CKTextContainer: NSTextContainer {
    override public func lineFragmentRectForProposedRect(proposedRect: CGRect, atIndex characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remainingRect: UnsafeMutablePointer<CGRect>) -> CGRect
    {
        let superReturnRect = super.lineFragmentRectForProposedRect(proposedRect, atIndex: characterIndex, writingDirection: baseWritingDirection, remainingRect: remainingRect)
        
        print("--------- ckTextContainer lineFragmentRectForProposedRect")
        print("proposedRect: \(proposedRect)")
        print("super return rect: \(superReturnRect)")
        print("characterIndex: \(characterIndex)")
        print("---------")
        
        return superReturnRect
    }
    
    
}
