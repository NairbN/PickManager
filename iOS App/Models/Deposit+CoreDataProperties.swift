//
//  Deposit+CoreDataProperties.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//
//

import Foundation
import CoreData


extension Deposit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Deposit> {
        return NSFetchRequest<Deposit>(entityName: "Deposit")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var amount: Double

}

extension Deposit : Identifiable {

}
