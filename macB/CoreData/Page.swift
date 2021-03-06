//
//  Page.swift
//  macB
//
//  Created by Denis Dobanda on 20.01.19.
//  Copyright © 2019 Denis Dobanda. All rights reserved.
//

import Foundation
import CoreData

class Page: NSManagedObject {
    class func get(with number: Int, from book: SpiritBook, searching context: NSManagedObjectContext) throws -> Page? {
        let req: NSFetchRequest<Page> = Page.fetchRequest()
        req.predicate = NSPredicate(format: "number == %@ AND chapter.book == %@", argumentArray: [number, book])
        
        let match = try context.fetch(req)
        if match.count > 0 {
            assert(match.count == 1, "Assert error: Page.get - Database inconsistency")
            return match[0]
        }
        return nil
    }
    
    class func from(_ sync: SyncSpiritPage, in context: NSManagedObjectContext) -> Page {
        let new = Page(context: context)
        new.number = Int32(sync.number)
        new.roman = sync.roman
//        new.text = sync.text
        let paragraphs = sync.text.split(separator: "\n")
        var ps = [SpiritParagraph]()
        for paragraph in paragraphs {
            let p = SpiritParagraph(context: context)
            p.text = String(paragraph)
            ps.append(p)
        }
        new.paragraphs = NSOrderedSet(array: ps)
        return new
    }
    
    class func find(number: Int, code: String, in context: NSManagedObjectContext) throws -> Page? {
        let request: NSFetchRequest<Page> = Page.fetchRequest()
        request.predicate = NSPredicate(format: "number = %@ AND chapter.book.code MATCHES [cd] %@", argumentArray: [number, code])
        let match = try context.fetch(request)
        return match.first
    }
}
