//
//  SpiritBook.swift
//  macB
//
//  Created by Denis Dobanda on 20.01.19.
//  Copyright © 2019 Denis Dobanda. All rights reserved.
//

import Foundation
import CoreData

class SpiritBook: NSManagedObject {
    class func getAll(from context: NSManagedObjectContext) throws -> [SpiritBook] {
        let request: NSFetchRequest<SpiritBook> = SpiritBook.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "index", ascending: true),
            NSSortDescriptor(key: "lang", ascending: true)
        ]
        return try context.fetch(request)
    }
    
    class func get(by code: String, from context: NSManagedObjectContext) throws -> SpiritBook? {
        let request: NSFetchRequest<SpiritBook> = SpiritBook.fetchRequest()
        request.predicate = NSPredicate(format: "code = %@", argumentArray: [code])
        
        let matches = try context.fetch(request)
        if matches.count > 0 {
            assert(matches.count == 1, "SpiritBook: inconsistency error")
            return matches[0]
        }
        return nil
    }
}
