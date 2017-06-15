//
//  UIImage+PodBundle.swift
//  Pods
//
//  Created by Leonardo Hammer on 02/06/2017.
//
//

import Foundation

extension UIImage {
	class func podImage(named: String) -> UIImage? {
		let bundle = Bundle(path: Bundle(for: LEOTextView.self).path(forResource: "LEOTextView", ofType: "bundle")!)
		return UIImage(named: named, in: bundle, compatibleWith: nil)
	}
}
