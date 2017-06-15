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
		
		let fontButton = UIBarButtonItem(image: UIImage.podImage(named: "icon-font"),
				style: .plain, target: self, action: #selector(fontAction))
		let refButton = UIBarButtonItem(image: UIImage.podImage(named: "icon-ref"),
				style: .plain, target: self, action: #selector(refAction))
		let listButton = UIBarButtonItem(image: UIImage.podImage(named: "icon-list"),
				style: .plain, target: self, action: #selector(listAction))
		let checkBoxButton = UIBarButtonItem(image: UIImage.podImage(named: "icon-checkbox"),
				style: .plain, target: self, action: #selector(checkBoxAction))
		let imageButton = UIBarButtonItem(image: UIImage.podImage(named: "icon-image"),
				style: .plain, target: self, action: #selector(imageAction))

		contentToolbar.items = [fontButton, fixedSpace, refButton, fixedSpace, listButton, fixedSpace, checkBoxButton,
								fixedSpace, imageButton, flexibleSpace, doneButton]
		contentToolbar.items?.forEach({ (barButtonItem) in
			barButtonItem.tintColor = UIColor.darkGray
		})
		contentToolbar.sizeToFit()
		
		self.inputAccessoryView = contentToolbar
    }
	
	// MARK: - Actions
	
	func fontAction() {
		
	}

	func refAction() {

	}

	func listAction() {

	}

	func checkBoxAction() {
		let checkboxAttachment = NSTextAttachment()
		checkboxAttachment.image = UIImage.podImage(named: "checkbox-unchecked")
		let checkboxAttributedString = NSAttributedString(attachment: checkboxAttachment)
		
		nck_textStorage.safeReplaceCharactersInRange(selectedRange, withAttributedString: checkboxAttributedString)
	}

	func imageAction() {

	}
	
	func doneAction() {
		self.resignFirstResponder()
	}
}
