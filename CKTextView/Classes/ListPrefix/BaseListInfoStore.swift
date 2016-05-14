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
    var backgroundViewWithBezierMadeReadable: UIView?
    
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
            
            backgroundViewWithBezierMadeReadable?.removeFromSuperview()
            backgroundViewWithBezierMadeReadable = nil
        }
    }
    
    /// Call this method to create a UIBezierPath to made text exclude from container.
    func fillBezierPath(ckTextView: CKTextView) {
        let lineHeight = ckTextView.font!.lineHeight
        
        let origin = CGPoint(x: 0, y: listStartByY)
        let size = CGSize(width: lineHeight + 10, height: listEndByY - listStartByY + lineHeight)
        let rect = CGRect(origin: origin, size: size)
        
        let newBezierPath = UIBezierPath(rect: rect)
        
        print("fill bezierPath with rect: \(rect)")
        
        ckTextView.textContainer.exclusionPaths.append(newBezierPath)
        
        clearBezierPath(ckTextView)
        
        bezierPath = newBezierPath
        
        backgroundViewWithBezierMadeReadable = UIView(frame: rect)
        backgroundViewWithBezierMadeReadable?.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.2)
        ckTextView.addSubview(backgroundViewWithBezierMadeReadable!)
    }
}
