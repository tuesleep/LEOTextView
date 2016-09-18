# NCKTextView

[![CI Status](https://travis-ci.org/chanricle/NCKTextView.svg?branch=master)](https://travis-ci.org/Chanricle King/NCKTextView)
[![codebeat badge](https://codebeat.co/badges/2889cc4f-85ed-4c14-b761-943a5bce2f8e)](https://codebeat.co/projects/github-com-chanricle-ncktextview)
[![Version](https://img.shields.io/cocoapods/v/NCKTextView.svg?style=flat)](http://cocoapods.org/pods/NCKTextView)
[![License](https://img.shields.io/cocoapods/l/NCKTextView.svg?style=flat)](http://cocoapods.org/pods/NCKTextView)
[![Platform](https://img.shields.io/badge/platform-iOS%209%2B-green.svg)](http://cocoapods.org/pods/NCKTextView)

NCKTextView is a **very high-performance** rich editor. Because it's a **subclass of UITextView**, not UIWebView. All of code by **TextKit** framework.

## Features

* Bold Text
* Italic Text
* Unordered List
* Ordered List
* List auto indentation
* Undo and Redo
* Rich Text Copy & Paste

## Requirements

Xcode 7.3 or newer

Tag       | Swift
--------  | -----
<= 0.4.1  | 2.2
>= 0.5.0  | 3.0

## Usage
Not extends any class, not EditorController and so on...

You can embed NCKTextView to anywhere that you want.

```swift
// Init TextView
let textView = NCKTextView(frame: self.view.bounds, textContainer: NSTextContainer())

// If you want to use built-in toolbar, call it.
textView.enableToolbar()

// add to View
self.view.addSubview(textView)
```

Done.

## UITextViewDelegate

Some feature I use delegate method, so NCKTextView is delegate self. And provide another delegate property named `nck_delegate`

```swift
public var nck_delegate: UITextViewDelegate?
```

## Public methods
#### Type transform

```swift
public func changeCurrentParagraphTextWithInputFontMode(mode: NCKInputFontMode)
public func changeSelectedTextWithInputFontMode(mode: NCKInputFontMode)

public func changeCurrentParagraphToOrderedList(orderedList isOrderedList: Bool, listPrefix: String)
```

#### Text attributes persistent

Get JSON by
```swift
public func textAttributesJSON() -> String
```

This method return a JSON string that contains all attributes needs to reload.

A unordered list 
- A
- B
- C

convert to JSON look like:

```json
{
  "text" : "- A\n- B\n- C",
  "attributes" : [
    {
      "location" : 0,
      "length" : 11,
      "fontType" : "normal",
      "name" : "NSFont"
    },
    {
      "location" : 0,
      "length" : 11,
      "listType" : 3,
      "name" : "NSParagraphStyle"
    }
  ]
}
```

Set JSON and display to UITextView by
```swift
public func setAttributeTextWithJSONString(jsonString: String)
```

Or just set attributes only by
```swift
public func setAttributesWithJSONString(jsonString: String)
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

![demo](https://github.com/chanricle/CKTextView/blob/develop/demo.gif?raw=true)

## Installation

###Stable source code

```
git clone -b master https://github.com/chanricle/NCKTextView.git
```

###Cocoapods

NCKTextView is available through CocoaPods. To install it, simply add the following line to your Podfile:

```
pod "NCKTextView"
```

## Author

Chanricle King, chanricle@icloud.com

## License

NCKTextView is available under the MIT license. See the LICENSE file for more info.
