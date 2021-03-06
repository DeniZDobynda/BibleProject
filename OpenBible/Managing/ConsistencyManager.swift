//
//  ConsistencyManager.swift
//  OpenBible
//
//  Created by Denis Dobanda on 20.02.19.
//  Copyright © 2019 Denis Dobanda. All rights reserved.
//

import Foundation
import CoreData

class ConsistencyManager: NSObject {
    var context: NSManagedObjectContext
    var delegates: [ConsistencyManagerDelegate]?
    
    private let lightDumpName = "Light.dmp"
    
    private var overallCountOfEntitiesToLoad = 0
    private var processedEntities = 0
    private var timer: Timer?
    private var updateIsOngoing = false
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func initialiseCoreData() {
        if let data = readFile(named: lightDumpName),
            let sync = parse(data) {
            for m in sync.modules {
                _ = Module.from(m, in: context)
            }
            try? context.save()
            self.broadcastChange()
        }
    }
    
    private func readFile(named: String) -> Data? {
        do {
            if let path = Bundle.main.path(forResource: named, ofType: nil) {
                let url = URL(fileURLWithPath: path)
                let d = try Data(contentsOf: url)
                return d
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func download(file: String, completition: @escaping (Bool) -> () ) {
        guard let url = URL(string: AppDelegate.downloadServerURL + file) else {completition(false);return}
        let context = AppDelegate.context
        didStartUpdate()
        overallCountOfEntitiesToLoad += 1
        Downloader.load(url: url) { (tempPath) in
            guard let temp = tempPath else {
                self.processedEntities += 1
                self.broadcastProgress()
                completition(false)
                return
            }
            do {
                let data = try Data(contentsOf: temp)
                if file.matches(SharingRegex.module),
                    let module = self.parse(module: data) {
                    _ = Module.from(module, in: context)
                    try? context.save()
                    self.processedEntities += 1//Module.checkConsistency(of: m, in: self.context)
                    self.broadcastProgress()
                } else if file.matches(SharingRegex.strong),
                    let sync = self.parse(strong: data) {
                    for str in sync {
                        _ = Strong.from(str, in: context)
                    }
                    try? context.save()
                    self.processedEntities += 1
                    self.broadcastProgress()
                } else if file.matches(SharingRegex.spirit),
                    let spirit = self.parse(spirit: data) {
                    _ = SpiritBook.from(spirit, in: context)
                    try? context.save()
                    self.processedEntities += 1//SpiritBook.checkConsistency(of: b, in: self.context)
                    self.broadcastChange()
                }
            } catch {
                print(error)
                self.processedEntities += 1
                self.broadcastProgress()
                completition(false)
            }
            completition(true)
        }
    }
    
    func remove(_ code: String, completition: @escaping () -> ()) {
        let context = AppDelegate.context
        overallCountOfEntitiesToLoad += 1
        didStartUpdate()
        DispatchQueue.global(qos: .userInitiated).async {
            if let key = SharingRegex.parseModule(code) {
                if let module = try? Module.get(by: key, from: context) {
                    context.delete(module)
                    try? context.save()
                }
//                AppDelegate.coreManager.update(true)
                completition()
                
            } else if let type = SharingRegex.parseStrong(code) {
                Strong.remove(type, from: context)
                try? context.save()
//                AppDelegate.coreManager.update(true)
                completition()
            } else if let c = SharingRegex.parseSpirit(code) {
                if let b = try? SpiritBook.get(by: c, from: context) {
                    context.delete(b)
                    try? context.save()
                }
//                AppDelegate.coreManager.update(true)
                completition()
            }
            self.processedEntities += 1
            self.broadcastProgress()
        }
    }
    
    private func broadcastProgress() {
        if !updateIsOngoing {
            updateIsOngoing = true
            didStartUpdate()
        }
        if processedEntities >= overallCountOfEntitiesToLoad {
            didEndUpdate()
            updateIsOngoing = false
            processedEntities = 0
            overallCountOfEntitiesToLoad = 0
        }
    }
    
    private func didStartUpdate() {
        delegates?.forEach {$0.consistentManagerDidStartUpdate?()}
    }
    
    private func didEndUpdate() {
        delegates?.forEach {$0.consistentManagerDidEndUpdate?()}
    }
    
    private func broadcastChange() {
        delegates?.forEach {$0.consistentManagerDidChangedModel?()}
    }
}

extension ConsistencyManager {
    private func parse(_ data: Data) -> SyncCore? {
        NSKeyedUnarchiver.setClass(SyncCore.self, forClassName: "macB.SyncCore")
        NSKeyedUnarchiver.setClass(SyncModule.self, forClassName: "macB.SyncModule")
        NSKeyedUnarchiver.setClass(SyncBook.self, forClassName: "macB.SyncBook")
        NSKeyedUnarchiver.setClass(SyncChapter.self, forClassName: "macB.SyncChapter")
        NSKeyedUnarchiver.setClass(SyncVerse.self, forClassName: "macB.SyncVerse")
        NSKeyedUnarchiver.setClass(SyncSpiritBook.self, forClassName: "macB.SyncSpiritBook")
        NSKeyedUnarchiver.setClass(SyncSpiritPage.self, forClassName: "macB.SyncSpiritPage")
        NSKeyedUnarchiver.setClass(SyncSpiritChapter.self, forClassName: "macB.SyncSpiritChapter")
        NSKeyedUnarchiver.setClass(SyncStrong.self, forClassName: "macB.SyncStrong")
        NSKeyedUnarchiver.setClass(SyncCore.self, forClassName: "compoundB.SyncCore")
        NSKeyedUnarchiver.setClass(SyncModule.self, forClassName: "compoundB.SyncModule")
        NSKeyedUnarchiver.setClass(SyncBook.self, forClassName: "compoundB.SyncBook")
        NSKeyedUnarchiver.setClass(SyncChapter.self, forClassName: "compoundB.SyncChapter")
        NSKeyedUnarchiver.setClass(SyncVerse.self, forClassName: "compoundB.SyncVerse")
        NSKeyedUnarchiver.setClass(SyncSpiritBook.self, forClassName: "compoundB.SyncSpiritBook")
        NSKeyedUnarchiver.setClass(SyncSpiritPage.self, forClassName: "compoundB.SyncSpiritPage")
        NSKeyedUnarchiver.setClass(SyncSpiritChapter.self, forClassName: "compoundB.SyncSpiritChapter")
        NSKeyedUnarchiver.setClass(SyncStrong.self, forClassName: "compoundB.SyncStrong")
        do {
            let core = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? SyncCore
            return core
        } catch {
            print(error)
        }
        return nil
    }
    
    private func parse(module data: Data) -> SyncModule? {
        NSKeyedUnarchiver.setClass(SyncModule.self, forClassName: "macB.SyncModule")
        NSKeyedUnarchiver.setClass(SyncBook.self, forClassName: "macB.SyncBook")
        NSKeyedUnarchiver.setClass(SyncChapter.self, forClassName: "macB.SyncChapter")
        NSKeyedUnarchiver.setClass(SyncVerse.self, forClassName: "macB.SyncVerse")
        NSKeyedUnarchiver.setClass(SyncModule.self, forClassName: "compoundB.SyncModule")
        NSKeyedUnarchiver.setClass(SyncBook.self, forClassName: "compoundB.SyncBook")
        NSKeyedUnarchiver.setClass(SyncChapter.self, forClassName: "compoundB.SyncChapter")
        NSKeyedUnarchiver.setClass(SyncVerse.self, forClassName: "compoundB.SyncVerse")
        do {
            let core = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? SyncModule
            return core
        } catch {
            print(error)
        }
        return nil
    }
    
    private func parse(strong data: Data) -> [SyncStrong]? {
        NSKeyedUnarchiver.setClass(SyncStrong.self, forClassName: "macB.SyncStrong")
        NSKeyedUnarchiver.setClass(SyncStrong.self, forClassName: "compoundB.SyncStrong")
        do {
            let core = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [SyncStrong]
            return core
        } catch {
            print(error)
        }
        return nil
    }
    
    private func parse(spirit data: Data) -> SyncSpiritBook? {
        NSKeyedUnarchiver.setClass(SyncSpiritBook.self, forClassName: "macB.SyncSpiritBook")
        NSKeyedUnarchiver.setClass(SyncSpiritPage.self, forClassName: "macB.SyncSpiritPage")
        NSKeyedUnarchiver.setClass(SyncSpiritChapter.self, forClassName: "macB.SyncSpiritChapter")
        NSKeyedUnarchiver.setClass(SyncSpiritBook.self, forClassName: "compoundB.SyncSpiritBook")
        NSKeyedUnarchiver.setClass(SyncSpiritPage.self, forClassName: "compoundB.SyncSpiritPage")
        NSKeyedUnarchiver.setClass(SyncSpiritChapter.self, forClassName: "compoundB.SyncSpiritChapter")
        do {
            let core = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? SyncSpiritBook
            return core
        } catch {
            print(error)
        }
        return nil
    }
}

extension ConsistencyManager {
    func addDelegate(_ del: ConsistencyManagerDelegate) {
        switch delegates {
        case .none:
            delegates = [del]
        case .some(_):
            delegates!.append(del)
        }
    }
    
    func removeDelegate(_ del: ConsistencyManagerDelegate) {
        switch delegates {
        case .some(var some):
            some.removeAll {$0.hash == del.hash}
        default: break
        }
    }
}


class Downloader {
    class func load(url: URL, completion: @escaping (URL?) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let task = session.downloadTask(with: request) { (tempLocalUrl, _, _) in
            completion(tempLocalUrl)
        }
        task.resume()
    }
}
