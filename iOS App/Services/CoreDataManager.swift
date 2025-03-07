//
//  CoreDataManager.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//

import Foundation
import CoreData

class CoreDataManager{
    static let shared = CoreDataManager()
    private init(){}
    
    private let context = PersistenceController.shared.container.viewContext
    
    // MARK: - Save Deposit (with auto-date)
    func saveDeposit(amount: Double) {
        let deposit = Deposit(context: context)
        deposit.amount = amount
        deposit.timestamp = Date()  // Automatically set the current date
        
        saveContext()
    }
    
    // MARK: - Save Balance (with auto-date)
    func saveBalance(amount: Double) {
        let balance = Balance(context: context)
        balance.amount = amount
        balance.timestamp = Date()  // Automatically set the current date
        
        saveContext()
    }
    
    // MARK: - Fetch Deposits
    func fetchDeposits() -> [Deposit] {
        let fetchRequest: NSFetchRequest<Deposit> = Deposit.fetchRequest()  // Correctly typed as NSFetchRequest<Deposit>
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch deposits: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Balances
    func fetchBalances() -> [Balance] {
        let fetchRequest: NSFetchRequest<Balance> = Balance.fetchRequest()  // Correctly typed as NSFetchRequest<Balance>
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch balances: \(error)")
            return []
        }
    }
    
    // MARK: - Delete All Data
    func deleteAllData() {
        // Delete all deposits
        let depositFetchRequest: NSFetchRequest<NSFetchRequestResult> = Deposit.fetchRequest()
        let depositDeleteRequest = NSBatchDeleteRequest(fetchRequest: depositFetchRequest)
        
        // Delete all balances
        let balanceFetchRequest: NSFetchRequest<NSFetchRequestResult> = Balance.fetchRequest()
        let balanceDeleteRequest = NSBatchDeleteRequest(fetchRequest: balanceFetchRequest)
        
        do {
            try context.execute(depositDeleteRequest)
            try context.execute(balanceDeleteRequest)
            saveContext()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
    
    // MARK: - Save Context
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
