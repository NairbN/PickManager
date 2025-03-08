//
//  FinanaceManagerViewModel.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn

class FinanceManagerViewModel: ObservableObject {
    @Published var account: Account? = nil
    @Published var accountRange: String? = ""
    @Published var deposits: [Deposit] = []
    @Published var balance: Double = 0.0
    @Published var totalDeposit: Double = 0.0
    @Published var depositAmount: String = ""
    @Published var currentBalanceAmount: String = ""
    
    @Published var sheetUpdateStatus: String? = nil  // Add status property

    private let sheetManager = GoogleSheetManager()
    private let googleSignInManager = GoogleSignInManager.shared  // Access GoogleSignInManager
    private var logCounter : Int = 1;
    
    func updateGoogleSheetWithData(amount: Double, range: String) {
        // Ensure user is signed in
        guard let user = googleSignInManager.currentUser else {
            print("User is not signed in.")
            DispatchQueue.main.async {
                self.sheetUpdateStatus = "Please sign in to update the sheet."
            }
            return
        }

        // Prepare data to write (ensure it's properly formatted)
        let values: [[String]] = [[String(format: "%.2f", amount)]]

        // Update the Google Sheet
        sheetManager.updateSheetData(range: range, values: values, authentication: user) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    print("Sheet updated successfully: \(message)")
                    self.sheetUpdateStatus = "Sheet updated successfully!"

                case .failure(let error):
                    print("Error updating sheet: \(error.localizedDescription)")
                    self.sheetUpdateStatus = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    
    
    
    
    func setAccount(accountName: String){
        if let account = CoreDataManager.shared.fetchAccountByName(name: accountName) {
            self.account = account
            self.accountRange = account.range
            loadAccountData()
        }
        
    }

    func loadAccountData() {
        guard let account = account else {
            print("❌ No account found in ViewModel")
            return
        }

        deposits = account.deposits?.allObjects as? [Deposit] ?? []
        balance = account.balance?.amount ?? 0.0
        totalDeposit = deposits.reduce(0) { $0 + $1.amount }

        print("✅ Loaded Account: \(account.name ?? "Unknown")")
        print("💰 Balance: \(balance), Total Deposits: \(totalDeposit)")
        print("📜 Deposits: \(deposits.map { "\($0.amount)" }.joined(separator: ", "))")
    }

    func saveDeposit() {
        guard let account = account, let accountRange = accountRange else { return }
        
        if let amount = Double(depositAmount) {
            CoreDataManager.shared.saveDeposit(amount: amount, to: account)
            loadAccountData()  // Ensure totalDeposit is updated
            
            depositAmount = ""

            // Log the deposit in Sheet2
            let logString = "Sheet2!A\(logCounter)"
            logCounter += 1

            updateGoogleSheetWithData(amount: amount, range: logString)

            // Update Total Deposits in Google Sheet (Column C of account row)
            let totalDepositRange = accountRange.replacingOccurrences(of: "B", with: "C") // "B2" -> "C2"
            updateGoogleSheetWithData(amount: totalDeposit, range: totalDepositRange)
        }
    }


    func saveBalance() {
        guard let account = account, let accountRange = accountRange else { return }
        
        if let amount = Double(currentBalanceAmount) {
            CoreDataManager.shared.saveBalance(amount: amount, to: account)
            loadAccountData()

            currentBalanceAmount = ""

            // Update Balance in Google Sheet (Column D of account row)
            let balanceRange = accountRange.replacingOccurrences(of: "B", with: "D") // "B2" -> "D2"
            updateGoogleSheetWithData(amount: amount, range: balanceRange)
        }
    }

    
    func resetAccountData() {
        guard let account = account else { return }
        CoreDataManager.shared.deleteAccountData(account: account)
        loadAccountData()
        updateGoogleSheetWithData(amount: totalDeposit, range: "Sheet1!A1")
        updateGoogleSheetWithData(amount: balance, range: "Sheet1!A2")
    }
    
    func signOut() {
        googleSignInManager.signOut()
    }
}
