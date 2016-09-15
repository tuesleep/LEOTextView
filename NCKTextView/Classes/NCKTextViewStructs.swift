//
//  NCKTextViewStructs.swift
//  Pods
//
//  Created by Chanricle King on 13/09/2016.
//
//

import Foundation

public enum NCKInputFontMode: Int {
    case Normal, Bold, Italic, Title
}

public enum NCKInputParagraphType: Int {
    case Title, Body, BulletedList, DashedList, NumberedList
}

struct NCKParagraph {
    var paragraphType: NCKInputParagraphType
    var range: NSRange
    var paragraphText: String
}
