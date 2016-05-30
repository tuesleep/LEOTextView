//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

public class CKTextView: UITextView, UITextViewDelegate, UIActionSheetDelegate {
    
    private var currentCursorType: ListType = .Text
    
    // Record current cursor point, to choose operations.
    private var prevCursorPoint: CGPoint?
    private var currentCursorPoint: CGPoint?
    
    private var prevTextHeight: CGFloat?
    private var currentTextHeight: CGFloat?
    
    private var willReturnTouch: Bool = false
    private var willBackspaceTouch: Bool = false
    private var willChangeText: Bool = false
    
    // Save Y and ListItem relationship.
    var listItemContainerMap: Dictionary<String, BaseListItem> = [:]
    
    // Save Y and InfoStore relationship.
    var listInfoStoreContainerMap: Dictionary<String, Int> = [:]
    
    private var ignoreMoveOnce = false
    
    private var toolbar: UIToolbar?
    
    // MARK: - Public
    
    public var isShowToolbar: Bool = true
 
    public class func ck_textView(frame: CGRect) -> CKTextView
    {
        let ckTextContainer = CKTextContainer(size: CGSize(width: CGRectGetWidth(frame), height: CGFloat.max))
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(ckTextContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        let ckTextView = CKTextView(frame: frame, textContainer: ckTextContainer)
        // Setting about TextView
        ckTextView.autocorrectionType = .No
        ckTextView.currentCursorPoint = CKTextUtil.cursorPointInTextView(ckTextView)
        
        return ckTextView
    }
    
    public func ck_setText(theText: String)
    {
        self.text = ""
        self.listItemContainerMap.forEach({ $0.1.clearGlyph(); $0.1.listInfoStore?.clearBezierPath(self) })
        self.listItemContainerMap.removeAll()
        self.listInfoStoreContainerMap.removeAll()
        self.currentCursorType = .Text
        
        pasteWithText(theText, sender: nil)
    }
    
    public func ck_text() -> String
    {
        return appendGlyphsWithText(text, range: NSMakeRange(0, text.characters.count))
    }
    
    public func reloadText() {
        self.ck_setText(self.ck_text())
    }
    
    public func changeSelectedTextToBody()
    {
        changeSelectedTextLineType(.Text)
    }
    
    public func changeSelectedTextToCheckbox()
    {
        changeSelectedTextLineType(.Checkbox)
    }
    
    public func changeSelectedTextToBulleted()
    {
        changeSelectedTextLineType(.Bulleted)
    }
    
    public func changeSelectedTextToNumbered()
    {
        changeSelectedTextLineType(.Numbered)
    }
    
    func createItemWithY(y: CGFloat, type: ListType) {
        var createdItem: BaseListItem?
        
        switch type {
        case .Checkbox:
            let checkBoxListItem = CheckBoxListItem(keyY: y, ckTextView: self, listInfoStore: nil)
            createdItem = checkBoxListItem
            
            break
        case .Bulleted:
            let bulletedListItem = BulletedListItem(keyY: y, ckTextView: self, listInfoStore: nil)
            createdItem = bulletedListItem
            
            break
        case .Numbered:
            let numberListItem = NumberedListItem(keyY: y, number: 1, ckTextView: self, listInfoStore: nil)
            createdItem = numberListItem
            
            break
        case .Text:
            break
        }
        
        if createdItem != nil {
            let lineHeight = self.font!.lineHeight
            
            createdItem!.listInfoStore!.fillBezierPath(self)
            
            saveToListItemContainerWithItem(createdItem!)
            saveToListInfoStoreContainerY(y: createdItem!.listInfoStore!.listStartByY)
            
            let itemTextHeight = CKTextUtil.itemTextHeightWithY(y, ckTextView: self)
            CKTextUtil.resetKeyYSetItem(createdItem!, startY: y, textHeight: itemTextHeight, lineHeight: lineHeight)
            
            createdItem?.resetAllItemYWithFirstItem(createdItem!, ckTextView: self)
            
            currentCursorType = createdItem!.listType()
            
            handleListMergeWhenLineTypeChanged(y, item: createdItem!)
        }
    }
    
    func changeSelectedTextLineType(type: ListType)
    {
        let selectedTextRange = self.selectedTextRange
        
        if selectedTextRange!.empty {
            // Before change to Text
            if let item = itemFromListItemContainerWithY(currentCursorPoint!.y) {
                item.destroy(self, byBackspace: false, withY: currentCursorPoint!.y)
            }
            
            // Get target y
            let targetY = CKTextUtil.lineHeadPointYWithPosition(selectedTextRange!.start, ckTextView: self)
            createItemWithY(targetY, type: type)
            
        } else {
            var moveTextPosition = self.selectedTextRange!.end
            
            while self.offsetFromPosition(self.selectedTextRange!.start, toPosition: moveTextPosition) > 0 {
                let currentTextLineHeadPosition = CKTextUtil.lineHeadPositionWithPosition(moveTextPosition, ckTextView: self)
                
                let y = CKTextUtil.lineHeadPointYWithLineHeadPosition(currentTextLineHeadPosition, ckTextView: self)
                
                // Delete item if exist
                if let item = itemFromListItemContainerWithY(y) {
                    item.destroy(self, byBackspace: false, withY: y)
                }
                
                createItemWithY(y, type: type)
                
                if offsetFromPosition(self.selectedTextRange!.start, toPosition: currentTextLineHeadPosition) == 0 {
                    break
                }
                
                moveTextPosition = positionFromPosition(currentTextLineHeadPosition, offset: -1)!
            }
        }
        
        handleInfoStoreContainerKeySetRight()
    }
    
    // MARK: - Initialized
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initialized()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialized()
    }
    
    func initialized()
    {
        self.delegate = self
        
        setupNotificationCenterObservers()
        
    }
    
    // MARK: - Container getter & setter
    
    func saveToListItemContainerWithItem(item: BaseListItem) {
        for (_, keyY) in item.keyYSet.enumerate() {
            listItemContainerMap[String(Int(keyY))] = item
        }
    }
    
    func removeListItemFromContainer(item: BaseListItem) {
        for (_, keyY) in item.keyYSet.enumerate() {
            listItemContainerMap.removeValueForKey(String(Int(keyY)))
        }
    }
    
    func itemFromListItemContainerWithY(y: CGFloat) -> BaseListItem?
    {
        return itemFromListItemContainerWithKeyY(String(Int(y)))
    }
    
    func itemFromListItemContainerWithKeyY(keyY: String) -> BaseListItem?
    {
        var y = (keyY as NSString).integerValue
        
        var item = listItemContainerMap[keyY]
        
        if item == nil {
            item = listItemContainerMap[String(y + 1)];
        }
        
        if item == nil {
            item = listItemContainerMap[String(y - 1)];
        }
        
        return item
    }
    
    func saveToListInfoStoreContainerY(y keyY: CGFloat)
    {
        listInfoStoreContainerMap[String(Int(keyY))] = 0
    }
    
    func removeInfoStoreFromContainerWithY(y keyY: CGFloat)
    {
        var key = String(Int(keyY))
        var infoStore = listInfoStoreContainerMap[key];
        
        if infoStore == nil {
            key = String(Int(keyY) + 1)
            infoStore = listInfoStoreContainerMap[key];
        }
        
        if infoStore == nil {
            key = String(Int(keyY) - 1)
            infoStore = listInfoStoreContainerMap[key];
        }
        
        listInfoStoreContainerMap.removeValueForKey(key)
    }
    
    // MARK: - Setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
    }
    
    // MARK: - Delete
    
    /**
        Do something about delete list item.
     
        - Returns: return bool value defined is delete first item of list.
     */
    func deleteListPrefixWithY(y: CGFloat, cursorPoint: CGPoint, byBackspace: Bool) -> Bool
    {
        var isDeleteFirstItem = false
        
        if let item = itemFromListItemContainerWithY(y)
        {
            isDeleteFirstItem = item.firstKeyY == item.listInfoStore!.listStartByY
            
            item.destroy(self, byBackspace: byBackspace, withY: y)
        }
        
        return isDeleteFirstItem
    }
    
    // MARK: - UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        handleUpdateCurrentCursorType()
        
        // Operate by select range.
        if CKTextUtil.isSelectedTextMultiLine(textView) {
            handleMultiLineWithShouldChangeTextInRange(range, replacementText: text, replacementTextCount: text.characters.count)
            return false
        }
        
        var isContinue = true
        
        if CKTextUtil.isSpace(text)
        {
            isContinue = handleSpaceEvent(textView)
        }
        else if CKTextUtil.isReturn(text)
        {
            willReturnTouch = true
            isContinue = handleReturnEvent(textView)
        }
        else if CKTextUtil.isBackspace(text)
        {
            willBackspaceTouch = true
            isContinue = handleBackspaceEvent(textView, deleteText: (textView.text as NSString).substringWithRange(range))
            
            if range.location == 0 && range.length == 0 {
                isContinue = false
            }
        }
        
        if isContinue {
            willChangeText = true
        } else {
            willChangeText = false
        }
        
        return isContinue
    }

    public func textViewDidChangeSelection(textView: UITextView) {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        handleTextHeightChangedAndUpdateCurrentCursorPoint(cursorPoint)
        
        handleInfoStoreContainerKeySetRight()
        
        willChangeText = false
        willReturnTouch = false
        willBackspaceTouch = false
        
        ignoreMoveOnce = false
        
        print("cursor type: \(currentCursorType)")
        print("list item container: \(listItemContainerMap)")
        print("list info store container: \(listInfoStoreContainerMap)")
    }
    
    public func textViewDidChange(textView: UITextView)
    {
        
    }
    
    // MARK: - Event Handler
    
    func handleMultiLineWithShouldChangeTextInRange(range: NSRange, replacementWithNormalText: String) {
        var keyText = CKTextUtil.changeToKeyTextWithNormalText(replacementWithNormalText, textView: self)
        
        if CKTextUtil.isFirstLocationInLineWithLocation(range.location, textView: self) {
            if itemFromListItemContainerWithY(currentCursorPoint!.y) != nil {
                keyText = keyText.substringFromIndex(keyText.startIndex.advancedBy(3))
            }
        } else {
            keyText = keyText.substringFromIndex(keyText.startIndex.advancedBy(3))
        }
        
        let noStyleText = CKTextUtil.changeToTextWithKeyText(keyText)
        
        handleMultiLineWithShouldChangeTextInRange(range, replacementText: keyText, replacementTextCount: noStyleText.characters.count)
    }
    
    func handleMultiLineWithShouldChangeTextInRange(range: NSRange, replacementText: String, replacementTextCount: Int)
    {
        let startY = self.caretRectForPosition(selectedTextRange!.start).origin.y
        let endY = self.caretRectForPosition(selectedTextRange!.end).origin.y
        
        let prevItemCount = listItemContainerMap.filter({ $0.0 == String(Int($0.1.firstKeyY)) && ($0.0 as NSString).integerValue <= Int(startY) }).count
        
        let containItemCount = listItemContainerMap.filter({ $0.0 == String(Int($0.1.firstKeyY)) && ($0.0 as NSString).integerValue > Int(startY) && ($0.0 as NSString).integerValue <= Int(endY) }).count
        
        let locationMoveValue = prevItemCount * 3
        let lengthMoveValue = containItemCount * 3
        
        let keyTextLocation = range.location + locationMoveValue
        let keyTextLength = range.length + lengthMoveValue
        
        let normalText = appendGlyphsWithText(self.text, range: NSMakeRange(0, self.text.characters.count))
        
        var keyText = CKTextUtil.changeToKeyTextWithNormalText(normalText, textView: self)
        
        var replaceEndIndex = keyText.startIndex.advancedBy(keyTextLocation + keyTextLength)
        
        // Stop out of range.
        var replaceEndMoveValue = keyTextLocation + keyTextLength
        if replaceEndMoveValue > keyText.characters.count {
            replaceEndMoveValue = keyText.characters.count
        }
        
        let replaceRange = Range(start: keyText.startIndex.advancedBy(keyTextLocation), end: keyText.startIndex.advancedBy(replaceEndMoveValue))
        
        keyText.replaceRange(replaceRange, with: replacementText)
        
        let finalText = CKTextUtil.changeToNormalTextWithKeyText(keyText, textView: self)
        ck_setText(finalText)
        
        let cursorLocation = range.location + replacementTextCount
        self.selectedRange = NSMakeRange(cursorLocation, 0)
    }
    
    func handleInfoStoreContainerKeySetRight()
    {
        listInfoStoreContainerMap.map({
            if let firstItem = itemFromListItemContainerWithKeyY($0.0) {
                firstItem.clearContainerWithAllYSet(self)
                firstItem.resetAllItemYWithFirstItem(firstItem, ckTextView: self)
            } else {
                listInfoStoreContainerMap.removeValueForKey($0.0)
            }
        })
    }
    
    func handleSpaceEvent(textView: UITextView) -> Bool
    {
        if currentCursorType != ListType.Text {
            return true
        }
        
        let cursorLocation = textView.selectedRange.location
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
        // Keyword input will convert to List style.
        switch CKTextUtil.typeForListKeywordWithLocation(cursorLocation, textView: textView) {
        case .Numbered:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 2, 2), textView: textView)
            
            let numberedListItem = NumberedListItem(keyY: cursorPoint.y, number: 1, ckTextView: self, listInfoStore: nil)
            
            numberedListItem.listInfoStore?.fillBezierPath(self)
            
            // Save to container
            saveToListItemContainerWithItem(numberedListItem)
            saveToListInfoStoreContainerY(y: numberedListItem.listInfoStore!.listStartByY)
            
            currentCursorType = ListType.Numbered
            
            textView.selectedRange = NSMakeRange(cursorLocation - 2, 0)
            
            handleListMergeWhenLineTypeChanged(cursorPoint.y, item: numberedListItem)
            
            return false
            
        case .Bulleted:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 1, 1), textView: textView)
            
            let bulletedListItem = BulletedListItem(keyY: cursorPoint.y, ckTextView: self, listInfoStore: nil)
            
            bulletedListItem.listInfoStore?.fillBezierPath(self)
            
            // Save to container
            saveToListItemContainerWithItem(bulletedListItem)
            saveToListInfoStoreContainerY(y: bulletedListItem.listInfoStore!.listStartByY)
            
            currentCursorType = ListType.Bulleted
            
            textView.selectedRange = NSMakeRange(cursorLocation - 1, 0)
            
            handleListMergeWhenLineTypeChanged(cursorPoint.y, item: bulletedListItem)
            
            return false
        case .Checkbox:
            CKTextUtil.clearTextByRange(NSMakeRange(cursorLocation - 2, 2), textView: textView)
            
            let checkBoxListItem = CheckBoxListItem(keyY: cursorPoint.y, ckTextView: self, listInfoStore: nil)
            
            checkBoxListItem.listInfoStore?.fillBezierPath(self)
            
            saveToListItemContainerWithItem(checkBoxListItem)
            saveToListInfoStoreContainerY(y: checkBoxListItem.listInfoStore!.listStartByY)
            
            currentCursorType = ListType.Checkbox
            
            textView.selectedRange = NSMakeRange(cursorLocation - 2, 0)
            
            handleListMergeWhenLineTypeChanged(cursorPoint.y, item: checkBoxListItem)
            
            return false
        case .Text:
            return true
        }
    }
    
    func handleReturnEvent(textView: UITextView) -> Bool
    {
        let cursorLocation = textView.selectedRange.location
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        let lineHeight = textView.font!.lineHeight
        
        let isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
        
        if currentCursorType != ListType.Text
        {
            if isFirstLocationInLine {
                let isEmptyLine = CKTextUtil.isEmptyLine(cursorLocation, textView: textView)
                
                if isEmptyLine {
                    deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: false)
                    currentCursorType = .Text
                    willReturnTouch = false
                    
                    return false
                } else {
                    if let item = itemFromListItemContainerWithY(cursorPoint.y) {
                        handleListItemYConflictIfNeeded(item.listInfoStore!)
                        
                        item.createNextItemWithY(cursorPoint.y + lineHeight, ckTextView: self)
                    }
                }
                
            } else {
                if let item = itemFromListItemContainerWithY(cursorPoint.y) {
                    handleListItemYConflictIfNeeded(item.listInfoStore!)
                    
                    item.createNextItemWithY(cursorPoint.y + lineHeight, ckTextView: self)
                }
            }
        }
        
        return true
    }
    
    func handleBackspaceEvent(textView: UITextView, deleteText: String) -> Bool
    {
        let cursorPoint = CKTextUtil.cursorPointInTextView(textView)
        
        if currentCursorType != ListType.Text {
            let cursorLocation = textView.selectedRange.location
            
            let isFirstLocationInLine = CKTextUtil.isFirstLocationInLineWithLocation(cursorLocation, textView: textView)
            
            if isFirstLocationInLine {
                // If delete first character.
                let isDeleteFirstItem = deleteListPrefixWithY(cursorPoint.y, cursorPoint: cursorPoint, byBackspace: true)
                
                if isDeleteFirstItem {
                    // Do not delete prev '\n' char when first item deleting. And set cursorType to Text.
                    currentCursorType = ListType.Text
                    
                    if deleteText == "\n" {
                        return false
                    }
                } else {
                    if let item = itemFromListItemContainerWithY(cursorPoint.y) {
                        currentCursorType = item.listType()
                    } else {
                        currentCursorType = .Text
                    }
                }
            }
        }
        
        return true
    }
    
    func handleLineChanged(y: CGFloat, moveValue: CGFloat)
    {
        if ignoreMoveOnce {
            ignoreMoveOnce = false
            return
        }
        
        if moveValue < 0 {
            handleListMergeWhenBackspace(y, moveValue: moveValue)
        }
        
        let filterY = y + 0.1
        
        let infoStores = listInfoStoreContainerMap.filter { (keyY, infoStore) -> Bool in
            let listFirstY = (keyY as NSString).floatValue
            
            if listFirstY > Float(filterY) {
                return true
            } else {
                return false
            }
        }
        
        // Sort array DESC to fix conflict.
        let infoStoresSortDesc: [(String, Int)]!
            
        if moveValue > 0 {
            infoStoresSortDesc = infoStores.sort({ ($0.0 as NSString).floatValue > ($1.0 as NSString).floatValue })
        } else {
            infoStoresSortDesc = infoStores.sort({ ($0.0 as NSString).floatValue < ($1.0 as NSString).floatValue })
        }
        
        for (firstKeyY, _) in infoStoresSortDesc {
            guard let item = listItemContainerMap[firstKeyY] else { continue }
            
            item.clearContainerWithAllYSet(self)
            
            item.firstKeyY = item.firstKeyY + moveValue
            
            item.resetAllItemYWithFirstItem(item, ckTextView: self)
        }
    }
    
    func handleListMergeWhenBackspace(y: CGFloat, moveValue: CGFloat) {
        // this line type must equal Text
        if moveValue < 0 && itemFromListItemContainerWithY(y) == nil {
            // By backspace, needs link same list if existed.
            let prevY = y + moveValue
            let nextY = y + self.font!.lineHeight
            
            guard let prevItem = itemFromListItemContainerWithY(prevY), nextItem = itemFromListItemContainerWithY(nextY) else { return }
            guard prevItem.listType() == nextItem.listType() else { return }
            guard let firstItem = itemFromListItemContainerWithY(prevItem.listInfoStore!.listStartByY) else { return }
            
            removeInfoStoreFromContainerWithY(y: nextItem.listInfoStore!.listStartByY)
            
            prevItem.nextItem = nextItem
            nextItem.prevItem = prevItem
            
            nextItem.listInfoStore!.clearBezierPath(self)
        }
    }
    
    /**
        Handle that prev or next list can be merged.
     
        - Parameter y: item point y.
        - Parameter item: created item that on the point y.
     
        - Returns: true if merged success.
     */
    func handleListMergeWhenLineTypeChanged(y: CGFloat, item: BaseListItem) -> Bool {
        let prevY = y - self.font!.lineHeight + 0.1
        
        // Support multi-line mode.
        let nextY = y + (CGFloat(item.keyYSet.count) * self.font!.lineHeight) + 0.1
        
        // Merge two list that have same type when new list item create that have same type too.
        let prevItem = itemFromListItemContainerWithY(prevY), nextItem = itemFromListItemContainerWithY(nextY)
        
        if prevItem != nil && prevItem == nextItem {
            print("dead loop: prevItem == nextItem")
        }
        
        var firstItem: BaseListItem?
        
        // Merge prev list!
        if prevItem != nil && prevItem!.listType() == item.listType() {
            if prevItem == item {
                print("dead loop: prevItem == item")
            }
            
            item.prevItem = prevItem
            prevItem!.nextItem = item
            
            // Clear BezierPath when item not a firstItem in the list.
            item.listInfoStore?.clearBezierPath(self)
            removeInfoStoreFromContainerWithY(y: item.listInfoStore!.listStartByY)
            
            firstItem = itemFromListItemContainerWithY(prevItem!.listInfoStore!.listStartByY)
        }
        
        // Merge next list
        if nextItem != nil && nextItem?.listType() == item.listType() {
            if prevItem == item {
                print("dead loop: nextItem == item")
            }
            
            item.nextItem = nextItem
            nextItem!.prevItem = item
            
            nextItem!.listInfoStore!.clearBezierPath(self)
            removeInfoStoreFromContainerWithY(y: nextItem!.listInfoStore!.listStartByY)
            
            if firstItem == nil {
                firstItem = item
            }
        }
        
        if firstItem != nil {
            firstItem!.resetAllItemYWithFirstItem(firstItem!, ckTextView: self)
        } else {
            item.resetAllItemYWithFirstItem(item, ckTextView: self)
        }
        
        return true
    }
    
    func handleListItemYConflictIfNeeded(infoStore: BaseListInfoStore) {
        let lineHeight = self.font!.lineHeight
        let firstItemY = infoStore.listEndByY + lineHeight
        
        if listInfoStoreContainerMap[String(Int(firstItemY))] != nil {
            handleLineChanged(infoStore.listEndByY, moveValue: lineHeight)
            
            // Add to ignore move container.
            ignoreMoveOnce = true
        }
    }
    
    func handleTextHeightChangedAndUpdateCurrentCursorPoint(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
     
        print("cursorY changed to: \(currentCursorPoint?.y), prev cursorY: \(prevCursorPoint!.y)")
        
        if currentTextHeight == nil {
            currentTextHeight = CKTextUtil.textHeightForTextView(self)
            return
        }
        
        prevTextHeight = currentTextHeight
        currentTextHeight = CKTextUtil.textHeightForTextView(self)
        
        guard prevTextHeight != nil else { return }
        
        print("prevTextHeight: \(prevTextHeight); currentTextHeight: \(currentTextHeight)")
        
        // TextHeight changed, needs reload all item keyYSet and move some items.
        if currentTextHeight != prevTextHeight {
            let lineHeight = self.font!.lineHeight
            let textMoveValue = currentTextHeight! - prevTextHeight!
            
            let item = itemFromListItemContainerWithY(prevCursorPoint!.y)
            
            handleLineChanged(prevCursorPoint!.y, moveValue: textMoveValue)
        }
        
        // Update List type
        handleUpdateCurrentCursorType()
    }
    
    func handleUpdateCurrentCursorType()
    {
        // Update List type
        let item = itemFromListItemContainerWithY(currentCursorPoint!.y)
        currentCursorType = item == nil ? ListType.Text : item!.listType()
    }
    
    // MARK: - Cut & Copy & Paste
    
    public override func cut(sender: AnyObject?) {
        copy(sender)
        let copyText = UIPasteboard.generalPasteboard().string
        
        super.cut(sender)
        UIPasteboard.generalPasteboard().string = copyText
    }
    
    public override func copy(sender: AnyObject?) {
        super.copy(sender)
        
        let selectedText = CKTextUtil.textByRange(self.selectedRange, text: self.text)
        let selectedRange = self.selectedRange
        
        let copyText = appendGlyphsWithText(selectedText, range: selectedRange)
        
        UIPasteboard.generalPasteboard().string = copyText
        
//        print("Text copied: \(copyText)")
    }
    
    public override func paste(sender: AnyObject?) {
        guard let pasteText = UIPasteboard.generalPasteboard().string else { return }
//        print("textview paste invoke. paste content: \(pasteText)")
        
        // Every paste needs reload all text
        handleMultiLineWithShouldChangeTextInRange(self.selectedRange, replacementWithNormalText: pasteText)
    }
    
    // MARK: - Convert
    
    func appendGlyphsWithText(text: String, range: NSRange) -> String
    {
        var allLineString = (text as NSString).componentsSeparatedByString("\n")
        
        var numberedItemIndex = 1
        // move location record current range location of string.
        var moveLocationValue = 0
        
        let beginPosition = positionFromPosition(beginningOfDocument, offset: range.location)
        
        for (index, lineString) in allLineString.enumerate() {
            let currentPosition = self.positionFromPosition(beginPosition!, offset: moveLocationValue)
            let currentY = self.caretRectForPosition(currentPosition!).origin.y
            
            if let item = itemFromListItemContainerWithY(currentY) {
                var prefixString: String! = ""
                
                switch item.listType() {
                case .Numbered:
                    prefixString = "\(numberedItemIndex). "
                    numberedItemIndex += 1
                    
                    break
                case .Bulleted:
                    prefixString = "* "
                    
                    numberedItemIndex = 1
                    
                    break
                case .Checkbox:
                    let checkBoxListItem = item as! CheckBoxListItem
                    
                    if checkBoxListItem.isChecked {
                        prefixString = "- [x] "
                    } else {
                        prefixString = "- [ ] "
                    }
                    
                    numberedItemIndex = 1
                    
                    break
                case .Text:
                    break
                }
                
                let lineStringWithPrefix = prefixString + lineString
                
                allLineString[index] = lineStringWithPrefix
                
            } else {
                // Normal text
                // Nothing needs to do.
            }
            
            // add 1 for '\n' char length.
            moveLocationValue += lineString.characters.count + 1
        }
        
        let textAppended = allLineString.joinWithSeparator("\n")
        
        return textAppended
    }
    
    func pasteWithText(pasteText: String, sender: AnyObject?)
    {
        let cursorPoint = CKTextUtil.cursorPointInTextView(self)
        let pasteLocation = self.selectedRange.location
        
        var allLineCharacters = (pasteText as NSString).componentsSeparatedByString("\n")
        
        var numberIndex = 1
        
        for (index, character) in allLineCharacters.enumerate() {
            let listType = CKTextUtil.typeOfCharacter(character, numberIndex: numberIndex)
            
            let textHeightAndNewText = CKTextUtil.heightWithText(character, textView: self, listType: listType, numberIndex: numberIndex)
            let newCharacter = textHeightAndNewText.1
            
            if listType == ListType.Numbered {
                numberIndex += 1
            } else {
                numberIndex = 1
            }
            
            // Change characters, remove prefix keyword.
            allLineCharacters[index] = newCharacter
        }
        
        var finalPasteText = allLineCharacters.joinWithSeparator("\n")
        self.text = finalPasteText
        
        // Create items logic begin
        var allLineCharactersCreation = (pasteText as NSString).componentsSeparatedByString("\n")
        var createdItems: [BaseListItem] = []
        var moveY = cursorPoint.y
        
        numberIndex = 1
        
        let lineHeight = self.font!.lineHeight
        
        for (index, character) in allLineCharactersCreation.enumerate() {
            var listType = CKTextUtil.typeOfCharacter(character, numberIndex: numberIndex)
            
            let textHeightAndNewText = CKTextUtil.heightWithText(character, textView: self, listType: listType, numberIndex: numberIndex)
            var textHeight = textHeightAndNewText.0
            
            if listType == ListType.Numbered {
                numberIndex += 1
            } else {
                numberIndex = 1
            }
            
            if listType != .Text {
                var item: BaseListItem!
                
                switch listType {
                case .Numbered:
                    item = NumberedListItem(keyY: moveY, number: 1, ckTextView: self, listInfoStore: nil)
                    break
                case .Bulleted:
                    item = BulletedListItem(keyY: moveY, ckTextView: self, listInfoStore: nil)
                    break
                case .Checkbox:
                    let checkBoxListItem = CheckBoxListItem(keyY: moveY, ckTextView: self, listInfoStore: nil)
                    
                    if character.rangeOfString("- [x] ") != nil {
                        checkBoxListItem.isChecked = true
                    }
                    checkBoxListItem.changeCheckBoxButtonBg()
                    
                    item = checkBoxListItem
                    
                    break
                case .Text:
                    break
                }
                
                CKTextUtil.resetKeyYSetItem(item, startY: moveY, textHeight: textHeight, lineHeight: lineHeight)
                saveToListItemContainerWithItem(item)
                
                handleListMergeWhenLineTypeChanged(moveY, item: item)
            }
            
            if index > 0 {
                currentCursorType = listType
            }
            
            moveY += textHeight
        }
        
        handleInfoStoreContainerKeySetRight()
    }
    
    // MARK: - Toolbar button event
    
    func bodyButtonAction(button: UIBarButtonItem)
    {
        changeSelectedTextToBody()
    }
    
    func checkboxButtonAction(button: UIBarButtonItem)
    {
        changeSelectedTextToCheckbox()
    }
    
    func bulletedButtonAction(button: UIBarButtonItem)
    {
        changeSelectedTextToBulleted()
    }
    
    func numberedButtonAction(button: UIBarButtonItem)
    {
        changeSelectedTextToNumbered()
    }
    
    func hideKeyboardAction(button: UIBarButtonItem)
    {
        toolbar?.hidden = true
        self.resignFirstResponder()
    }
    
    // MARK: - KVO
    
    func keyboardDidShow(notification: NSNotification)
    {
        if let userInfo: NSDictionary = notification.userInfo {
            let value = userInfo["UIKeyboardBoundsUserInfoKey"]
            if let rect = value?.CGRectValue() {
                self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: rect.height + 44, right: 0)
                
                // Show toolbar if needed.
                if isShowToolbar {
                    toolbar?.removeFromSuperview()
                    toolbar = nil
                    
                    let screenSize = UIScreen.mainScreen().bounds.size
                    toolbar = UIToolbar(frame: CGRect(x: 0, y: screenSize.height - rect.height - 44, width: screenSize.width, height: 44))
                    
                    // Buttons
                    let bodyButton = UIBarButtonItem(title: "⌧", style: .Plain, target: self, action: #selector(self.bodyButtonAction(_:)))
                    let checkBoxButton = UIBarButtonItem(title: "◎", style: .Plain, target: self, action: #selector(self.checkboxButtonAction(_:)))
                    let bulletButton = UIBarButtonItem(title: "●", style: .Plain, target: self, action: #selector(self.bulletedButtonAction(_:)))
                    let numberButton = UIBarButtonItem(title: "1. ", style: .Plain, target: self, action: #selector(self.numberedButtonAction(_:)))
                    
                    let hideKeyboardButton = UIBarButtonItem(title: "⇣", style: .Plain, target: self, action: #selector(self.hideKeyboardAction(_:)))
                    
                    let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
                    
                    toolbar?.items = [flexibleSpaceButton, bodyButton, flexibleSpaceButton, checkBoxButton, flexibleSpaceButton, bulletButton, flexibleSpaceButton, numberButton, flexibleSpaceButton, hideKeyboardButton, flexibleSpaceButton]
                    
                    self.window?.addSubview(toolbar!)
                }
            }
        }
    }
    
    func keyboardDidHide(notification: NSNotification)
    {
        toolbar?.removeFromSuperview()
        toolbar = nil
    }
}
