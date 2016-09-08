# NCKTextView

[![CI Status](http://img.shields.io/travis/Chanricle King/NCKTextView.svg?style=flat)](https://travis-ci.org/Chanricle King/NCKTextView)
[![Version](https://img.shields.io/cocoapods/v/NCKTextView.svg?style=flat)](http://cocoapods.org/pods/NCKTextView)
[![License](https://img.shields.io/cocoapods/l/NCKTextView.svg?style=flat)](http://cocoapods.org/pods/NCKTextView)
[![Platform](https://img.shields.io/cocoapods/p/NCKTextView.svg?style=flat)](http://cocoapods.org/pods/NCKTextView)

NCKTextView is a **very high-performance** rich editor. Because it's a **subclass of UITextView**, not UIWebView. All of code by **TextKit** framework.

## Features

* Bold Text
* Italic Text
* Unordered List
* Ordered List
* List auto indentation
* Undo and Redo
* Rich Text Copy & Paste

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

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

![demo](https://github.com/chanricle/CKTextView/blob/develop/demo.gif?raw=true)

## Requirements

Xcode 7.3 +

Swift 2.2 +

## Installation

###Stable source code

```
git clone -b stable https://github.com/chanricle/NCKTextView.git
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
