//
//  BaseListInfoStore.swift
//  Pods
//
//  Created by Chanricle King on 5/10/16.
//
//

import UIKit

class BaseListInfoStore: NSObject {
    /// used for excluding the specified text area.
    ///
    /// All item of list used one Bezier path to excluding text area.
    var bezierPath: UIBezierPath?
    
    var listStartByY: CGFloat!
    var listEndByY: CGFloat!
    
    required init(listStartByY: CGFloat, listEndByY: CGFloat) {
        self.listStartByY = listStartByY
        self.listEndByY = listEndByY
    }
    
    func clearBezierPath(ckTextView: CKTextView) {
        if bezierPath != nil {
            if let pathIndex = ckTextView.textContainer.exclusionPaths.indexOf(bezierPath!) {
                ckTextView.textContainer.exclusionPaths.removeAtIndex(pathIndex)
            }
            
            bezierPath = nil
        }
    }
    
    /// Call this method to create a UIBezierPath to made text exclude from container.
    func fillBezierPath(ckTextView: CKTextView) {
        let lineHeight = ckTextView.font!.lineHeight
        
        clearBezierPath(ckTextView)
        
        let origin = CGPoint(x: 0, y: listStartByY)
        let size = CGSize(width: lineHeight + 10, height: listEndByY - listStartByY + 0.1)
        let rect = CGRect(origin: origin, size: size)
        
        bezierPath = UIBezierPath(rect: rect)
        bezierPath?.lineWidth = 1
    
        bezierPath?.stroke()
        
        print("fill bezierPath with rect: \(rect)")
        
        ckTextView.textContainer.exclusionPaths.append(bezierPath!)
    }
}
