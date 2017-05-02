//
//  LEOTextViewStructs.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation

public enum LEOInputFontMode: Int {
    case normal, bold, italic, title
}

public enum LEOInputParagraphType: Int {
    case title, body, bulletedList, dashedList, numberedList
}

struct LEOParagraph {
    var paragraphType: LEOInputParagraphType
    var range: NSRange
    var paragraphText: String
}
