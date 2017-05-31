//
//  LEOTextView+Toolbar.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

extension LEOTextView {
    /**
     Enable the toolbar, binding the show and hide events.

     */
	public func enableToolbar(_ view: UIView) {
		let bundle = podBundle()
		
		let contentToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
		contentToolbar.barStyle = .default
		
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
		fixedSpace.width = 20
		
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
		doneButton.width = 50
		
		let fontButton = UIBarButtonItem(image: UIImage(named: "icon-font", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(fontAction))
		
		contentToolbar.items = [fontButton, flexibleSpace, doneButton]
		contentToolbar.items?.forEach({ (barButtonItem) in
			barButtonItem.tintColor = UIColor.darkGray
		})
		contentToolbar.sizeToFit()
		
		self.inputAccessoryView = contentToolbar
    }
	
	// MARK: - Actions
	
	func fontAction() {
		
	}
	
	func doneAction() {
		self.resignFirstResponder()
	}
}
