//
//  Account+CoreDataProperties.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/8/25.
//
//

import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    @NSManaged public var name: String?
    @NSManaged public var range: String?
    @NSManaged public var balance: Balance?
    @NSManaged public var deposits: NSSet?

}

// MARK: Generated accessors for deposits
extension Account {

    @objc(addDepositsObject:)
    @NSManaged public func addToDeposits(_ value: Deposit)

    @objc(removeDepositsObject:)
    @NSManaged public func removeFromDeposits(_ value: Deposit)

    @objc(addDeposits:)
    @NSManaged public func addToDeposits(_ values: NSSet)

    @objc(removeDeposits:)
    @NSManaged public func removeFromDeposits(_ values: NSSet)

}

extension Account : Identifiable {

}
