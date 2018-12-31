//
//  Strong.swift
//  macB
//
//  Created by Denis Dobanda on 30.12.18.
//  Copyright © 2018 Denis Dobanda. All rights reserved.
//

import Foundation
import CoreData

class Strong: NSManagedObject {
    
    class func getAll(_ context: NSManagedObjectContext) throws -> [Strong] {
        let req: NSFetchRequest<Strong> = Strong.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        
        return try context.fetch(req)
    }
    
    class func get(by type: String, from context: NSManagedObjectContext) throws -> [Strong] {
        let req: NSFetchRequest<Strong> = Strong.fetchRequest()
        req.predicate = NSPredicate(format: "type = %@", argumentArray: [type])
        req.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        
        return try context.fetch(req)
    }
    
    class func get(_ number: Int, by type: String, from context: NSManagedObjectContext) -> Strong? {
        let req: NSFetchRequest<Strong> = Strong.fetchRequest()
        req.predicate = NSPredicate(format: "number = %@ AND type = %@", argumentArray: [number, type])
        
        do {
            let matches = try context.fetch(req)
            if matches.count > 0 {
                return matches[0]
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    class func get(by type: String, searched: String, from context: NSManagedObjectContext) -> [Strong] {
        let req: NSFetchRequest<Strong> = Strong.fetchRequest()
        req.predicate = NSPredicate(format: "(meaning MATCHES *%@* OR original MATHCES *%@* ) AND type = %@", argumentArray: [searched, searched, type])
        
        do {
            let matches = try context.fetch(req)
            return matches
        } catch {
            print(error)
        }
        return []
    }
    
}
