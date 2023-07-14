//
//  LEOTextView+Toolbar.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

public var toolbar: UIToolbar?
public var toolbarHeight: CGFloat = 40
public var currentFrame: CGRect = CGRect.zero

public var toolbarButtonTintColor: UIColor = UIColor.black
public var toolbarButtonHighlightColor: UIColor = UIColor.orange

var formatButton: UIBarButtonItem?

var nck_formatTableViewController: LEOFormatTableViewController?
var formatMenuView: UIView?

extension LEOTextView {

    /**
     Remove toolbar notifications
     */

    public func removeToolbarNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     Enable the toolbar, binding the show and hide events.

     */
    public func enableToolbar() -> UIToolbar {
        toolbar = UIToolbar(frame: CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height), size: CGSize(width: UIScreen.main.bounds.width, height: toolbarHeight)))
        toolbar?.autoresizingMask = .flexibleWidth
        toolbar?.backgroundColor = UIColor.clear

        toolbar?.items = enableBarButtonItems()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        currentFrame = self.frame

        return toolbar!
    }

    // MARK: - Toolbar buttons

    func enableBarButtonItems() -> [UIBarButtonItem] {
        let bundle = podBundle()

        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let hideKeyboardButton = UIBarButtonItem(image: UIImage(named: "icon-keyboard", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(self.hideKeyboardButtonAction))

        formatButton = UIBarButtonItem(image: UIImage(named: "icon-format", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(self.formatButtonAction))

        let buttonItems = [formatButton!, flexibleSpaceButton, hideKeyboardButton]

        // Button styles
        for buttonItem in buttonItems {
            buttonItem.tintColor = toolbarButtonTintColor
        }

        return buttonItems
    }

    @objc func formatButtonAction() {
        if formatMenuView == nil {
            let bundle = podBundle()

            let nck_formatNavigationController = UIStoryboard(name: "LEOTextView", bundle: bundle).instantiateViewController(withIdentifier: "LEOFormatNavigationController") as! UINavigationController

            nck_formatTableViewController = nck_formatNavigationController.viewControllers[0] as? LEOFormatTableViewController
            nck_formatTableViewController?.selectedCompletion = { [unowned self] (type) in

                switch type {
                case .title:
                    self.inputFontMode = .title
                    self.changeCurrentParagraphTextWithInputFontMode(.title)

                    break
                case .body:
                    self.inputFontMode = .normal

                    if self.currentParagraphType() == .title {
                        self.changeCurrentParagraphTextWithInputFontMode(.normal)
                    }

                    break
                case .bulletedList:
                    if self.currentParagraphType() == .title {
                        self.changeCurrentParagraphTextWithInputFontMode(.normal)
                    }

                    self.changeCurrentParagraphToOrderedList(orderedList: false, listPrefix: "• ")

                    break
                case .dashedList:
                    if self.currentParagraphType() == .title {
                        self.changeCurrentParagraphTextWithInputFontMode(.normal)
                    }

                    self.changeCurrentParagraphToOrderedList(orderedList: false, listPrefix: "- ")

                    break
                case .numberedList:
                    if self.currentParagraphType() == .title {
                        self.changeCurrentParagraphTextWithInputFontMode(.normal)
                    }

                    self.changeCurrentParagraphToOrderedList(orderedList: true, listPrefix: "1. ")

                    break
                }
            }

            let superViewSize = self.superview!.bounds.size
            let toolbarOriginY = toolbar!.frame.origin.y
            let menuViewHeight: CGFloat = toolbarOriginY - 200 >= 44 ? 180 : 120

            nck_formatNavigationController.view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: superViewSize.width, height: menuViewHeight))

            formatMenuView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: toolbarOriginY + 44 - menuViewHeight), size: CGSize(width: superViewSize.width, height: menuViewHeight)))
            formatMenuView?.addSubview(nck_formatNavigationController.view)

            nck_formatTableViewController?.navigationItem.title = NSLocalizedString("Formatting", comment: "")
            nck_formatTableViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.formatMenuViewDoneButtonAction))
        }

        self.superview?.addSubview(formatMenuView!)
    }

    @objc func formatMenuViewDoneButtonAction() {
        formatMenuView?.removeFromSuperview()
    }

    @objc func hideKeyboardButtonAction() {
        self.resignFirstResponder()
    }

    @objc func keyboardWillShowOrHide(_ notification: Notification) {
        guard let info = (notification as NSNotification).userInfo else {
            return
        }

        guard self.superview != nil else {
            return
        }

        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let keyboardEnd = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        let toolbarHeight = toolbar!.frame.size.height

        if notification.name == UIResponder.keyboardWillShowNotification {
            formatMenuView?.removeFromSuperview()

            self.superview?.addSubview(toolbar!)

            var textViewFrame = self.frame
            textViewFrame.size.height = self.superview!.frame.height - keyboardEnd.height - toolbarHeight
            self.frame = textViewFrame

            UIView.animate(withDuration: duration, animations: {
                var frame = toolbar!.frame
                frame.origin.y = self.superview!.frame.height - (keyboardEnd.height + toolbarHeight)
                toolbar!.frame = frame
            }, completion: nil)
        } else {
            self.frame = currentFrame

            UIView.animate(withDuration: duration, animations: {
                var frame = toolbar!.frame
                frame.origin.y = self.superview!.frame.size.height
                toolbar!.frame = frame

            }, completion: { (success) in
                toolbar!.removeFromSuperview()
            })

            formatMenuView?.removeFromSuperview()
        }
    }
}
