//
//  ModuleViewController.swift
//  macB
//
//  Created by Denis Dobanda on 23.12.18.
//  Copyright © 2018 Denis Dobanda. All rights reserved.
//

import Cocoa

class ModuleViewController: NSViewController {

    var moduleManager: VerseManager { return AppDelegate.coreManager }
    var currentModule: Module!
    var index: Int!
    var delegate: SplitViewDelegate?
    
    private var scrollDelegates: [SplitViewParticipant]?
    private var scrollViewIsOccupied = false
    private var textStorage: NSTextStorage?
    private var choise: [String] = []
    private var contentOffset: CGFloat {
        let docView = scrollView.documentView!.bounds.height
        let content = scrollView.contentSize.height
        guard docView - content != 0 else {return 1.0}
        return scrollView.documentVisibleRect.origin.y / (docView - content)
    }
    private var updateTimer: Timer?
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet private weak var modulePicker: NSComboBox!
    @IBOutlet private weak var scrollView: NSScrollView!
    @IBOutlet weak var closeButton: NSButton!
    
    private var strings: [NSAttributedString]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndScrolling(_:)),
            name: NSScrollView.didEndLiveScrollNotification,
            object: scrollView
        )
        scrollView.verticalScroller?.isHidden = true
        moduleManager.addDelegate(self)
        reloadUI()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        reloadUI()
    }
    
    private func updateCombo() {
        modulePicker?.removeAllItems()
        modulePicker?.addItem(withObjectValue: currentModule.key ?? currentModule.name ?? "Bible")
        let keys = moduleManager.getAllAvailableModulesKey()
        modulePicker?.addItems(withObjectValues: keys)
        choise = keys
        
        modulePicker?.selectItem(at: 0)
    }
    
    func updateUI() {
        collectionView.reloadData()
    }
    
    private func reloadUI() {
        if index == 0 {
            closeButton.isHidden = true
        }
        updateCombo()
        guard let index = index else {return}
        if index >= moduleManager.modules.count {
            delegate?.splitViewWouldLikeToResign(being: index)
        }
        strings = moduleManager[index]
        collectionView.reloadData()
        
//        let attributedString = strings.reduce(NSMutableAttributedString()) { (res, each) -> NSMutableAttributedString in
//            res.append(each)
//            return res
//        }
//        if let lm = textView?.layoutManager {
//            textStorage?.removeLayoutManager(lm)
//            textStorage = NSTextStorage(attributedString: attributedString)
//            textStorage!.addLayoutManager(lm)
//            if let c = NSColor(named: NSColor.Name("linkTextColor")) {
//                textView?.linkTextAttributes = [.foregroundColor: c, .cursor: NSCursor.contextualMenu]
//            }
////            textView?.setSelectedRange(NSMakeRange(textView.string.count, 0))
//        }
        if AppDelegate.plistManager.isTooltipOn {
            loadTooltip()
        }
    }
    
    private func loadTooltip() {
        guard let index = index else {return}
        DispatchQueue.global(qos: .background).async {
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {
                (_) in
                self.strings = self.moduleManager.getAttributedString(from: index, loadingTooltip: true)
//                let attributedString = strings.reduce(NSMutableAttributedString()) { (r, each) -> NSMutableAttributedString in
//                    r.append(each)
//                    return r
//                }
                DispatchQueue.main.async {
//                    if let lm = self.textView?.layoutManager {
//                        self.textStorage = NSTextStorage(attributedString: attributedString)
//                        self.textStorage!.addLayoutManager(lm)
//                    }
                    self.collectionView.reloadData()
                    self.updateTimer = nil
                }
            }
            self.updateTimer?.fire()
        }
    }
    
    @IBAction func comboPicked(_ sender: NSComboBox) {
        if sender.indexOfSelectedItem > 0 {
            if let m = moduleManager.setActive(choise[sender.indexOfSelectedItem - 1], at: index) {
                currentModule = m
                reloadUI()
            }
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        updateCombo()
        return super.becomeFirstResponder()
    }
    
    @IBAction func closeAction(_ sender: NSButton) {
        delegate?.splitViewWouldLikeToResign(being: index)
    }
    
    @objc func scrollViewDidScroll(_ notification: Notification) {
//        print(notification)
        scrollView.verticalScroller?.isHidden = true
        if !scrollViewIsOccupied {
//            scrollView.verticalScroller?.isHidden = false
            broadcastChanges()
        }
    }
    
    @objc func scrollViewDidEndScrolling(_ notification: Notification) {
        if !scrollViewIsOccupied {
            broadcastEnding()
        }
    }
}

extension ModuleViewController: ModelUpdateDelegate {
    func modelChanged(_ fully: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            self?.reloadUI()
        }
    }
}

extension ModuleViewController: NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let width = collectionView.bounds.width - 10.0
        return CGSize(width: width, height:  moduleManager.layoutManager.calculateHeight(at: indexPath.item, with: width - 10.0))
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = NSStoryboard.main?.instantiateController(withIdentifier: "Text Item") as! TextCollectionViewItem
        
        if let s = strings {
            item.text = s.count > indexPath.item ? s[indexPath.item] : nil
        }
        item.index = (index, indexPath.item)
        item.delegate = moduleManager
        item.presentee = self
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return moduleManager.countMax
    }
}

extension ModuleViewController: SplitViewParticipant {
    func broadcastChanges() {
        scrollDelegates?.forEach {$0.splitViewParticipantDidScrolled(to: contentOffset)}
    }
    func broadcastEnding() {
        scrollDelegates?.forEach {$0.splitViewParticipantDidEndScrolling()}
    }
    func splitViewParticipantDidScrolled(to offsetRatio: CGFloat) {
        scrollViewIsOccupied = true
        var rect = scrollView.documentVisibleRect
        rect.origin.y = (scrollView.documentView!.bounds.height - rect.height) * offsetRatio
//        rect.origin.y = scrollView.conte * offsetRatio
        scrollView.contentView.scrollToVisible(rect)
        scrollView.verticalScroller?.isHidden = true
//        scrollView.scroll(rect.origin)
        
    }
    func splitViewParticipantDidEndScrolling() {
        scrollViewIsOccupied = false
//        scrollView.verticalScroller?.isHidden = false
//        scrollView.verticalScroller?.drawKnobSlot(in: scrollView.verticalScroller!.rect(for: .knob), highlight: false)
    }
    func addSplitViewParticipant(_ delegate: SplitViewParticipant) {
        if scrollDelegates == nil {
            scrollDelegates = [delegate]
            return
        }
        scrollDelegates?.append(delegate)
    }
    func removeSplitViewParticipant(_ delegate: SplitViewParticipant) {
        scrollDelegates?.removeAll {$0.hashValue == delegate.hashValue}
        if scrollDelegates?.count == 0 {
            scrollDelegates = nil
        }
    }
    func setSplitViewParticipants(_ delegates: [SplitViewParticipant]?) {
        scrollDelegates = delegates
    }
}
