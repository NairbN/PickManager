//
//  Balance+CoreDataProperties.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//
//

import Foundation
import CoreData


extension Balance {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Balance> {
        return NSFetchRequest<Balance>(entityName: "Balance")
    }

    @NSManaged public var amount: Double
    @NSManaged public var timestamp: Date?

}

extension Balance : Identifiable {

}
