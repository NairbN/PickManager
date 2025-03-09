//
//  CoreDataManager.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    // Access the shared context from PersistenceController
    var context: NSManagedObjectContext {
        return PersistenceController.shared.context
    }
    
    // MARK: - Save Deposit (with auto-date)
    func saveDeposit(amount: Double, to account: Account) {
        let deposit = Deposit(context: context)
        deposit.amount = amount
        deposit.timestamp = Date()  // Automatically set the current date
        
        account.addToDeposits(deposit)  // Associate the deposit with the account
        
        saveContext()
    }
    
    // MARK: - Save Balance (with auto-date)
    func saveBalance(amount: Double, to account: Account) {
        let balance = Balance(context: context)
        balance.amount = amount
        balance.timestamp = Date()  // Automatically set the current date
        
        account.balance = balance  // Associate balance with account
        
        saveContext()
    }

    // MARK: - Save Account Data
    func saveAccount(name: String, totalDeposits: Double, currentBalance: Double) {
        let account = Account(context: context)
        account.name = name

        saveBalance(amount: currentBalance, to: account)
        saveDeposit(amount: totalDeposits, to: account)

        do {
            try context.save()
            print("✅ Successfully saved account: \(name), Deposits: \(totalDeposits), Balance: \(currentBalance)")
        } catch {
            print("❌ Failed to save account: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Account by Name
    func fetchAccountByName(name: String) -> Account? {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let accounts = try context.fetch(fetchRequest)
            return accounts.first
        } catch {
            print("Failed to fetch account by name: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Accounts with Related Data (Balance & Deposits)
    func fetchAccounts() -> [Account] {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.relationshipKeyPathsForPrefetching = ["balance", "deposits"]  // Prefetch related data
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch manager accounts: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Deposits
    func fetchDeposits(for account: Account) -> [Deposit] {
        return account.deposits?.allObjects as? [Deposit] ?? []
    }
    
    // MARK: - Fetch Balances
    func fetchBalances(for account: Account) -> Balance? {
        return account.balance
    }
    
    // MARK: - Delete All Data
    func deleteAllData() {
        // Delete all deposits
        let depositFetchRequest: NSFetchRequest<NSFetchRequestResult> = Deposit.fetchRequest()
        let depositDeleteRequest = NSBatchDeleteRequest(fetchRequest: depositFetchRequest)
        
        // Delete all balances
        let balanceFetchRequest: NSFetchRequest<NSFetchRequestResult> = Balance.fetchRequest()
        let balanceDeleteRequest = NSBatchDeleteRequest(fetchRequest: balanceFetchRequest)
        
        // Delete all accounts
        let accountFetchRequest: NSFetchRequest<NSFetchRequestResult> = Account.fetchRequest()
        let accountDeleteRequest = NSBatchDeleteRequest(fetchRequest: accountFetchRequest)
        
        do {
            // Perform batch deletes
            try context.execute(depositDeleteRequest)
            try context.execute(balanceDeleteRequest)
            try context.execute(accountDeleteRequest)
            
            // Reset the context if necessary to reflect the changes
            context.reset()
            
            // Optionally save context if your saveContext method does something additional
            saveContext()
        } catch {
            print("Failed to delete all data: \(error.localizedDescription)")
        }
    }

    
    //Mark : - Google Sheets Value formated table
    func getTable() -> [[String]]{
        let accounts = fetchAccounts()
        var table: [[String]] = [[]]
        for account in accounts{
            let line:[String] = [account.name ?? "", String(getTotalDeposits(for: account) ?? 0), String(account.balance?.amount ?? 0)]
            table.append(line)
        }
        return table
    }
    
    // MARK: - Total Deposits
    func getTotalDeposits(for account: Account) -> Double?{
        let deposits = fetchDeposits(for: account)
        return deposits.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Delete Account Data
    func deleteAccountData(account: Account) {
        // Delete deposits for the account
        if let deposits = account.deposits?.allObjects as? [Deposit] {
            for deposit in deposits {
                context.delete(deposit)
            }
        }
        
        // Delete the account balance
        if let balance = account.balance {
            context.delete(balance)
        }

        // Delete the account itself
        context.delete(account)
        
        saveContext()
    }
    
    // MARK: - Reset Account Data
    func resetAccountData(account:Account){
        if let deposits = account.deposits?.allObjects as? [Deposit] {
            for deposit in deposits {
                context.delete(deposit)
            }
        }
        
        if let balance = account.balance {
            context.delete(balance)
        }
        
        saveDeposit(amount: 0, to: account)
        saveBalance(amount: 0, to: account)
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
