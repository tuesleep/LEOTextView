//
//  CKTextContainer.swift
//  Pods
//
//  Created by Chanricle King on 5/15/16.
//
//

import UIKit

class CKTextContainer: NSTextContainer {
    override func lineFragmentRectForProposedRect(proposedRect: CGRect, atIndex characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remainingRect: UnsafeMutablePointer<CGRect>) -> CGRect
    {
        let superReturnRect = super.lineFragmentRectForProposedRect(proposedRect, atIndex: characterIndex, writingDirection: baseWritingDirection, remainingRect: remainingRect)

        return superReturnRect
    }
}
