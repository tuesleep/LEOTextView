# NCKTextView

[![CI Status](http://img.shields.io/travis/Chanricle King/CKTextView.svg?style=flat)](https://travis-ci.org/Chanricle King/CKTextView)
[![Version](https://img.shields.io/cocoapods/v/CKTextView.svg?style=flat)](http://cocoapods.org/pods/CKTextView)
[![License](https://img.shields.io/cocoapods/l/CKTextView.svg?style=flat)](http://cocoapods.org/pods/CKTextView)
[![Platform](https://img.shields.io/cocoapods/p/CKTextView.svg?style=flat)](http://cocoapods.org/pods/CKTextView)

NCKTextView is a **very high-performance** rich editor. Because it's a **subclass of UITextView**, not UIWebView. All of code by **TextKit** framework.

## Features

* Bold Text
* Italic Text
* Unordered List
* Ordered List
* Undo and Redo

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

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

![demo](https://github.com/chanricle/CKTextView/blob/develop/demo.gif?raw=true)

## Requirements

Xcode 7.3 +

Swift 2.2 +

## Installation

## Author

Chanricle King, chanricle@icloud.com

## License

NCKTextView is available under the MIT license. See the LICENSE file for more info.
