//
//  CKTextChecker.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

class CKTextChecker: NSObject {
    class func isReturn(replacementText: String!) -> Bool
    {
        if replacementText == "\n" {
            return true
        } else {
            return false
        }
    }
    
    
}
