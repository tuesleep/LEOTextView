//
//  CKTextView.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

public class CKTextView: UITextView, UITextViewDelegate, UIActionSheetDelegate {
    // Record current cursor point, to choose operations.
    private var currentCursorPoint: CGPoint?
    private var currentCursorType: ListType = .Text
    
    private var prevCursorPoint: CGPoint?
    
    private var willReturnTouch: Bool = false
    private var willBackspaceTouch: Bool = false
    private var willChangeText: Bool = false
    private var willChangeTextMulti: Bool = false
    private var willPasteText: Bool = false
    
    public var ck_text: String! {
        set {
            let oldPasteText = UIPasteboard.generalPasteboard().string
            pasteWithText(newValue, sender: nil)
            UIPasteboard.generalPasteboard().string = oldPasteText
        }
        
        get {
            let beginPosition = self.beginningOfDocument
            let endPosition = self.endOfDocument
            
            return appendGlyphsWithText(text, textRange: self.textRangeFromPosition(beginPosition, toPosition: endPosition)!)
        }
    }
    
    // Save Y and ListItem relationship.
    var listItemContainerMap: Dictionary<String, BaseListItem> = [:]
    
    // Save Y and InfoStore relationship.
    var listInfoStoreContainerMap: Dictionary<String, Int> = [:]
    private var ignoreMoveOnce = false
    
    public class func ck_textView(frame: CGRect) -> CKTextView
    {
        let ckTextContainer = CKTextContainer(size: CGSize(width: CGRectGetWidth(frame), height: CGFloat.max))
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(ckTextContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        return CKTextView(frame: frame, textContainer: ckTextContainer)
    }
    
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
    
    // MARK: - Public method
    
    func reloadText() {
        
    }
    
    // MARK: - Container getter & setter
    
    func saveToListItemContainerWithItem(item: BaseListItem) {
        for (_, keyY) in item.keyYSet.enumerate() {
            listItemContainerMap[String(Int(keyY))] = item
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
        listInfoStoreContainerMap.removeValueForKey(String(Int(keyY)));
    }
    
    // MARK: - Setups
    
    func setupNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CKTextView.keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
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
            
            // reload
            changeCurrentCursorPointIfNeeded(cursorPoint)
        }
        
        return isDeleteFirstItem
    }
    
    // MARK: - UITextViewDelegate
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        
        // Operate by select range.
        let textInfo = CKTextUtil.checkChangedTextInfoAndHandleMutilSelect(textView, shouldChangeTextInRange: range, replacementText: text)
        
        if textInfo.1 {
            willChangeTextMulti = true
            
            handleMultiTextReplacement(textInfo)
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
            isContinue = handleBackspaceEvent(textView)
            
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
        changeCurrentCursorPointIfNeeded(cursorPoint)
        
        willChangeText = false
        willReturnTouch = false
        willBackspaceTouch = false
        willChangeTextMulti = false
        willPasteText = false
        
        ignoreMoveOnce = false
        
        print("cursor type: \(currentCursorType)")
        print("list item container: \(listItemContainerMap)")
        print("list info store container: \(listInfoStoreContainerMap)")
    }
    
    public func textViewDidChange(textView: UITextView)
    {
        
    }
    
    // MARK: - Event Handler
    
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
    
    func handleBackspaceEvent(textView: UITextView) -> Bool
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
                    
                    if !willChangeTextMulti {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func handleMultiTextReplacement(textInfo: ([String], Bool, CGFloat))
    {
        let needsRemoveItemYArray = textInfo.0
        
        for itemY in needsRemoveItemYArray {
            if let item = itemFromListItemContainerWithKeyY(itemY) {
                item.prevItem?.nextItem = item.nextItem
                item.clearGlyph()
                item.listInfoStore!.clearBezierPath(self)
                listItemContainerMap.removeValueForKey(itemY)
            }
        }
        
        for keyY in listInfoStoreContainerMap {
            if let firstItem = itemFromListItemContainerWithKeyY(keyY.0) {
                firstItem.resetAllItemYWithFirstItem(firstItem, ckTextView: self)
            }
        }
        
        handleLineChanged(CGFloat((needsRemoveItemYArray.last! as NSString).floatValue), moveValue: textInfo.2)
    }
    
    func handleLineChanged(y: CGFloat, moveValue: CGFloat)
    {
        if ignoreMoveOnce {
            ignoreMoveOnce = false
            return
        }
        
        handleListMergeWhenBackspace(y, moveValue: moveValue)
        
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
        
        // Paste text addition handle.
        if willPasteText {
            guard let pasteLocationItem = itemFromListItemContainerWithY(y) else { return }
            
            let lineHeight = self.font!.lineHeight
            
            guard let pasteEndItem = itemFromListItemContainerWithY(pasteLocationItem.listInfoStore!.listEndByY) else { return }
            
            var pasteLocationPrevItem = pasteEndItem
            
            while pasteLocationPrevItem != pasteLocationItem {
                listItemContainerMap.removeValueForKey(String(Int(pasteLocationPrevItem.firstKeyY)))
                
                pasteLocationPrevItem.firstKeyY = pasteLocationPrevItem.firstKeyY + moveValue
                CKTextUtil.resetKeyYSetItem(pasteLocationPrevItem, startY: pasteLocationPrevItem.firstKeyY, textHeight: CGFloat(pasteLocationPrevItem.keyYSet.count) * lineHeight, lineHeight: lineHeight)
                
                saveToListItemContainerWithItem(pasteLocationPrevItem)
                
                pasteLocationPrevItem = pasteLocationPrevItem.prevItem!
            }
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
            
            prevItem.resetAllItemYWithFirstItem(firstItem, ckTextView: self)
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
            print("dead loop")
            
            print("oh no")
        }
        
        var firstItem: BaseListItem?
        
        // Merge prev list!
        if prevItem != nil && prevItem!.listType() == item.listType() {
            item.prevItem = prevItem
            prevItem!.nextItem = item
            
            // Clear BezierPath when item not a firstItem in the list.
            item.listInfoStore?.clearBezierPath(self)
            removeInfoStoreFromContainerWithY(y: item.listInfoStore!.listStartByY)
            
            firstItem = itemFromListItemContainerWithY(prevItem!.listInfoStore!.listStartByY)
        }
        
        // Merge next list
        if nextItem != nil && nextItem?.listType() == item.listType() {
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
    
    func changeCurrentCursorPointIfNeeded(cursorPoint: CGPoint)
    {
        prevCursorPoint = currentCursorPoint
        currentCursorPoint = cursorPoint
        
        guard prevCursorPoint != nil else { return }
     
        print("cursorY changed to: \(currentCursorPoint?.y), prev cursorY: \(prevCursorPoint!.y)")
        
        if prevCursorPoint!.y != cursorPoint.y {
            // Handle all list that after this y position.
            if willChangeText {
                let moveValue = cursorPoint.y - prevCursorPoint!.y
                handleLineChanged(prevCursorPoint!.y, moveValue: moveValue)
            }
            
            guard !willReturnTouch else { return }
            
            // Text not change, only normal cursor moving.. Or backspace touched.
            if !willChangeText || willBackspaceTouch {
                let item = itemFromListItemContainerWithY(cursorPoint.y)
                
                currentCursorType = item == nil ? ListType.Text : item!.listType()
                
                return
            }
            
            // Text changed, something happend.
            // Handle too long string typed.. add moreline bezierPath space fill. and set key to container.
            if !willBackspaceTouch && !willPasteText {
                if let item = itemFromListItemContainerWithY(prevCursorPoint!.y)
                {
                    // key Y of New line add to container.
                    item.keyYSet.insert(cursorPoint.y)
                    saveToListItemContainerWithItem(item)
                    
                    // List item typed.. and changed line.
                    let firstItem = itemFromListItemContainerWithY(item.listInfoStore!.listStartByY)
                    firstItem?.resetAllItemYWithFirstItem(firstItem!, ckTextView: self)
                }
            }
        }
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
        let selectedRange = self.selectedTextRange!
        
        let copyText = appendGlyphsWithText(selectedText, textRange: selectedRange)
        
        UIPasteboard.generalPasteboard().string = copyText
        
        print("Text copied: \(copyText)")
    }
    
    public override func paste(sender: AnyObject?) {
        guard let pasteText = UIPasteboard.generalPasteboard().string else { return }
        print("textview paste invoke. paste content: \(pasteText)")
        
        pasteWithText(pasteText, sender: sender)
    }
    
    // MARK: - Convert
    
    func appendGlyphsWithText(text: String, textRange: UITextRange) -> String
    {
        // All of the point y in seleted text.
        let selectedPointYArray = CKTextUtil.seletedPointYArrayWithTextView(self, selectedRange: textRange, isContainFirstLine: true, sortByAsc: true)
        
        var allLineCharacters = (text as NSString).componentsSeparatedByString("\n")
        
        var numberedItemIndex = 1
        
        for (index, characters) in allLineCharacters.enumerate() {
            let seletedPointY = selectedPointYArray[index]
            if let item = itemFromListItemContainerWithKeyY(seletedPointY) where item.listType() != ListType.Text {
                var prefixCharacters: String! = ""
                
                switch item.listType() {
                case .Numbered:
                    prefixCharacters = "\(numberedItemIndex). "
                    numberedItemIndex += 1
                    
                    break
                case .Bulleted:
                    prefixCharacters = "* "
                    
                    numberedItemIndex = 1
                    
                    break
                case .Checkbox:
                    let checkBoxListItem = item as! CheckBoxListItem
                    
                    if checkBoxListItem.isChecked {
                        prefixCharacters = "- [x] "
                    } else {
                        prefixCharacters = "- [ ] "
                    }
                    
                    numberedItemIndex = 1
                    
                    break
                case .Text:
                    break
                }
                
                let newCharacters = prefixCharacters + characters
                
                allLineCharacters[index] = newCharacters
            }
        }
        
        let textAppended = allLineCharacters.joinWithSeparator("\n")
        
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
        
        willPasteText = true
        
        var finalPasteText = allLineCharacters.joinWithSeparator("\n")
        UIPasteboard.generalPasteboard().string = finalPasteText
        super.paste(sender)
        
        UIPasteboard.generalPasteboard().string = pasteText
        
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
            
            if let thisItem = itemFromListItemContainerWithY(moveY) {
                if index == 0 {
                    // Change type to Text in first index.
                    // First paste y just change to Text
                    listType = .Text
                    
                    // Update this item keyYSet.
                    let pastedTextInTextView = self.text.substringFromIndex(self.text.startIndex.advancedBy(pasteLocation)) as NSString
                    
                    let returnRange = pastedTextInTextView.rangeOfString("\n")
                    var pasteWithListItemEndLocation: Int
                    
                    if returnRange.location != NSNotFound {
                        // Maybe append 2 can fix this bug.
                        pasteWithListItemEndLocation = returnRange.location + 2
                    } else {
                        pasteWithListItemEndLocation = pastedTextInTextView.length
                    }
                    
                    let firstItemEndLocation = pasteWithListItemEndLocation + pasteLocation
                    
                    if let targetPosition = self.positionFromPosition(self.beginningOfDocument, offset: firstItemEndLocation) {
                        let point = self.caretRectForPosition(targetPosition).origin
                        
                        moveY = thisItem.firstKeyY
                        textHeight = point.y - thisItem.firstKeyY
                        
                        CKTextUtil.resetKeyYSetItem(thisItem, startY: thisItem.firstKeyY, textHeight: textHeight, lineHeight: lineHeight)
                        
                        saveToListItemContainerWithItem(thisItem)
                        
                        handleListMergeWhenLineTypeChanged(moveY, item: thisItem)
                    }
                    
                } else {
                    if thisItem.listType() != listType {
                        listType = thisItem.listType()
                    }
                    
                    // Handle point confict
                    thisItem.firstKeyY = moveY + textHeight
                    
                    CKTextUtil.resetKeyYSetItem(thisItem, startY: thisItem.firstKeyY, textHeight: lineHeight * CGFloat(thisItem.keyYSet.count), lineHeight: lineHeight)
                    saveToListItemContainerWithItem(thisItem)
                }
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
                
                handleListMergeWhenLineTypeChanged(moveY, item: item)
            }
            
            if index > 0 {
                currentCursorType = listType
            }
            
            moveY += textHeight
        }
    }
    
    // MARK: - KVO
    
    func keyboardWillShow(notification: NSNotification)
    {
        if let userInfo: NSDictionary = notification.userInfo {
            let value = userInfo["UIKeyboardBoundsUserInfoKey"]
            if let rect = value?.CGRectValue() {
                self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: rect.height + 100, right: 0)
            }
        }
    }
}
