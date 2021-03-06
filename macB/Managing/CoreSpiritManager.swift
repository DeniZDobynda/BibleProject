//
//  CoreSpiritManager.swift
//  macB
//
//  Created by Denis Dobanda on 02.04.19.
//  Copyright © 2019 Denis Dobanda. All rights reserved.
//

import Foundation
import CoreData

struct SpiritIndex {
    var book: String
    var chapter: Int
    var page: Int? = nil
    
    init(book: String, chapter: Int, page: Int? = nil) {
        self.book = book
        self.chapter = chapter
        self.page = page
    }
}

class CoreSpiritManager: NSObject {
    
    var context: NSManagedObjectContext = AppDelegate.context
    var currentIndex: SpiritIndex
    
    var index: Int = 0
    var delegate: ModelUpdateDelegate?
    
    
    private var timings: Timer?
//    private var pages: [Page]? = nil
    
    var shortPath: String {
        let number = Int(currentChapter()?.number ?? Int32(currentIndex.chapter + 1))
        return currentIndex.book + ":\(number)"
    }
    
    override init() {
        currentIndex = PlistManager.shared.getSpirit(from: index) ?? SpiritIndex(book: "", chapter: 0)
        //        currentIndesies = AppDelegate.plistManager.getSpirit()
        super.init()
    }
    
    func readyToDisplay() -> (String, Int)? {
        return (currentIndex.book, currentIndex.chapter)
    }
    
    func set(spiritIndex: SpiritIndex) -> Int {
        let pos = set(book: spiritIndex.book)
        setChapter(number: spiritIndex.chapter)
        broadcastChanges()
        return pos
    }
    
    func set(book: String) -> Int {
        currentIndex.book = book
        PlistManager.shared.setSpirit(currentIndex, at: index)
        broadcastChanges()
        return index
    }
    
    func setChapter(number: Int) {
        currentIndex.chapter = number
        PlistManager.shared.setSpirit(currentIndex, at: index)
        broadcastChanges()
    }
    
    func currentBook() -> SpiritBook? {
        return (((try? SpiritBook.get(by: currentIndex.book, from: context)) as SpiritBook??)) ?? nil
    }
    
    func currentChapter() -> SpiritChapter? {
        if let book = currentBook(), let chapters = book.chapters?.array as? [SpiritChapter] {
            if chapters.count > currentIndex.chapter {
                if chapters[currentIndex.chapter].index == Int32(currentIndex.chapter) {
                    return chapters[currentIndex.chapter]
                } else {
                    let fil = chapters.filter({$0.index == currentIndex.chapter})
                    if fil.count == 1 {
                        return fil[0]
                    } else {
                        print("Database inconsistency at SpiritManager.currentChapter(\(index))")
                    }
                }
            }
        }
        return nil
    }
    
    func stringValue() -> [NSAttributedString] {
        
        return []
    }
    
    private func broadcastChanges(_ full: Bool = false) {
        timings?.invalidate()
        timings = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (t) in
            self.delegate?.modelChanged(full)
            t.invalidate()
        }
        timings?.fire()
    }
    
    func update(_ full: Bool = false) {
        broadcastChanges(full)
    }
    
    func doSearch(_ text: String) {
        if text.matches(String.regexForSpiritIndex) {
            let match = text.capturedGroups(withRegex: String.regexForSpiritIndex)!
            if match.count > 0, SpiritBook.exists(with: match[0], in: context) {
                currentIndex.book = match[0]
                PlistManager.shared.setSpirit(currentIndex, at: index)
                broadcastChanges()
                if match.count > 1 {
                    if match[1] == ":", match.count > 2 {
                        currentIndex.chapter = Int(match[2])!
                        PlistManager.shared.setSpirit(currentIndex, at: index)
                        broadcastChanges()
                        return
                    } else {
                        //                        pages = []
                        //                        if let page = Page.get(with: Int(match[1]), from: SpiritBook.ge, searching: <#T##NSManagedObjectContext#>)
                    }
                }
            }
        }
    }
    
    func clearSearch() {
        currentIndex.page = nil
        broadcastChanges()
    }
}
