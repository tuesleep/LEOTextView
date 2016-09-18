//
//  NCKTextViewStructs.swift
//  Pods
//
//  Created by Chanricle King on 13/09/2016.
//
//

import Foundation

public enum NCKInputFontMode: Int {
    case normal, bold, italic, title
}

public enum NCKInputParagraphType: Int {
    case title, body, bulletedList, dashedList, numberedList
}

struct NCKParagraph {
    var paragraphType: NCKInputParagraphType
    var range: NSRange
    var paragraphText: String
}
