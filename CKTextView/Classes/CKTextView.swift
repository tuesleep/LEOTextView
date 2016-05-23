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
    var currentCursorPoint: CGPoint?
    var currentCursorType: ListType = .Text
    
    var prevCursorPoint: CGPoint?
    
    var willReturnTouch: Bool = false
    var willBackspaceTouch: Bool = false
    var willChangeText: Bool = false
    
    // Save Y and ListItem relationship.
    var listItemContainerMap: Dictionary<String, BaseListItem> = [:]
    
    // Save Y and InfoStore relationship.
    var listInfoStoreContainerMap: Dictionary<String, Int> = [:]
    var ignoreMoveOnce = false
    
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
    
    // MARK: - Container getter & setter
    
    func saveToListItemContainerWithItem(item: BaseListItem) {
        for (_, keyY) in item.keyYSet.enumerate() {
            listItemContainerMap[String(Int(keyY))] = item
        }
    }
    
    func itemFromListItemContainerWithY(y: CGFloat) -> BaseListItem?
    {
        return listItemContainerMap[String(Int(y))]
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
        
        // TODO: mutli operate.
        // CKTextUtil.checkChangedTextInfo(textView, shouldChangeTextInRange: range, replacementText: text)
        
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
                    return false
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
        let nextY = y + self.font!.lineHeight + 0.1
        
        // TODO: Merge two list that have same type when new list item create that have same type too.
        
        let prevItem = itemFromListItemContainerWithY(prevY), nextItem = itemFromListItemContainerWithY(nextY)
        
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
            if !willBackspaceTouch {
                if let item = itemFromListItemContainerWithY(prevCursorPoint!.y)
                {
                    // key Y of New line add to container.
                    item.keyYSet.insert(cursorPoint.y)
                    saveToListItemContainerWithItem(item)
                    // TODO: change BeizerPathRect, more height
                }
            }
        }
    }
    
    // MARK: - Copy & Paste
    
//    public override func paste(sender: AnyObject?) {
//        print("textview paste invoke. paste content: \(UIPasteboard.generalPasteboard().string)")
//    }
    
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
