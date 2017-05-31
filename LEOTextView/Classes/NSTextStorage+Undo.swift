//
//  NSTextStorage+Undo.swift
//  Pods
//
//  Created by Leonardo Hammer on 31/05/2017.
//
//

import Foundation

extension NSTextStorage {
	func undoSupportReplaceRange(replaceRange: NSRange, withAttributedString attributedStr: NSAttributedString, oldAttributedString: NSAttributedString, selectedRangeLocationMove: Int, textView: UITextView) {
		textView.undoManager?.registerUndo(withTarget: self, handler: { (targetType) in
			self.undoSupportReplaceRange(replaceRange: replaceRange, withAttributedString: attributedStr, oldAttributedString: oldAttributedString, selectedRangeLocationMove: selectedRangeLocationMove, textView: textView)
		})
		
		if textView.undoManager!.isUndoing {
			let targetSelectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, textView.selectedRange.length)
			safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, NSString(string: attributedStr.string).length), withAttributedString: oldAttributedString)
			textView.selectedRange = targetSelectedRange
		} else {
			let targetSelectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, textView.selectedRange.length)
			safeReplaceCharactersInRange(replaceRange, withAttributedString: attributedStr)
			textView.selectedRange = targetSelectedRange
		}
	}
}
