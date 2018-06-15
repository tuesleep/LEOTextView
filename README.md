# LEOTextView

[![CI Status](http://img.shields.io/travis/leonardo-hammer/LEOTextView.svg?style=flat)](https://travis-ci.org/leonardo-hammer/LEOTextView)
[![Version](https://img.shields.io/cocoapods/v/LEOTextView.svg?style=flat)](http://cocoapods.org/pods/LEOTextView)
[![License](https://img.shields.io/cocoapods/l/LEOTextView.svg?style=flat)](http://cocoapods.org/pods/LEOTextView)
[![Platform](https://img.shields.io/cocoapods/p/LEOTextView.svg?style=flat)](http://cocoapods.org/pods/LEOTextView)

LEOTextView is a **very high-performance** rich editor. Because it's a **subclass of UITextView**, not UIWebView. All of code by **TextKit** framework.

## Features

* Bold Text
* Italic Text
* Unordered List
* Ordered List
* List auto indentation
* Undo and Redo
* Rich Text Copy & Paste

## Requirements

Xcode 8.3 or newer

Tag       | Swift
--------  | -----
<= 0.4.x  | 2.2
\>= 0.5.0  | 3.0
\>= 0.7.0  | 4.0

## Usage

Not extends any class, not EditorController and so on...

You can embed LEOTextView to anywhere that you want.

```swift
// Init TextView
let textView = LEOTextView(frame: self.view.bounds, textContainer: NSTextContainer())

// If you want to use built-in toolbar, call it.
textView.enableToolbar()

// add to View
self.view.addSubview(textView)
```

Done.

## UITextViewDelegate

Some feature I use delegate method, so LEOTextView is delegate self. And provide another delegate property named `leo_delegate`

```swift
public var leo_delegate: UITextViewDelegate?
```

## Public methods

#### Type transform

```swift
public func changeCurrentParagraphTextWithInputFontMode(mode: LEOInputFontMode)
public func changeSelectedTextWithInputFontMode(mode: LEOInputFontMode)

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
  "text": "- A\n- B\n- C",
  "attributes": [
  {
    "location": 0,
    "length": 11,
    "fontType": "normal",
    "name": "NSFont"
  },
  {
    "location": 0,
    "length": 11,
    "listType": 3,
    "name": "NSParagraphStyle"
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

## Installation

### Cocoapods

LEOTextView is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
pod "LEOTextView"
```

## Author

Tuesleep, tuesleep@gmail.com

## License

LEOTextView is available under the MIT license. See the LICENSE file for more info.
