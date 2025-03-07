//
//  FinanaceManagerViewModel.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn

class FinanceManagerViewModel: ObservableObject {
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
        guard let signInResult = googleSignInManager.currentUser else {
            print("User is not signed in.")
            sheetUpdateStatus = "Please sign in to update the sheet."
            return
        }

        // The GIDSignInResult object contains the authentication token we need
        let values = [["\(amount)"]]
        
        sheetManager.updateGoogleSheet(range: range, values: values, authentication: signInResult) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    print("Sheet updated successfully: \(message)")
                    self.sheetUpdateStatus = "Sheet updated successfully!"
                case .failure(let error):
                    print("Error updating sheet: \(error.localizedDescription)")
                    self.sheetUpdateStatus = "Error updating sheet: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadData() {
        deposits = CoreDataManager.shared.fetchDeposits()
        balance = 0.0
        if let latestBalance = CoreDataManager.shared.fetchBalances().last {
            balance = latestBalance.amount
        }
        totalDeposit = deposits.reduce(0) { $0 + $1.amount }
    }

    func saveDeposit() {
        if let amount = Double(depositAmount) {
            CoreDataManager.shared.saveDeposit(amount: amount)
            loadData()
            depositAmount = ""
            let logString = "Sheet2!A" + String(logCounter)
            logCounter += 1
            updateGoogleSheetWithData(amount: amount, range: logString)
            updateGoogleSheetWithData(amount: totalDeposit, range: "Sheet1!A1")
        }
    }

    func saveBalance() {
        if let amount = Double(currentBalanceAmount) {
            CoreDataManager.shared.saveBalance(amount: amount)
            loadData()
            currentBalanceAmount = ""
            updateGoogleSheetWithData(amount: amount, range: "Sheet1!A2")
        }
    }

    func resetAllData() {
        CoreDataManager.shared.deleteAllData()
        loadData()
        updateGoogleSheetWithData(amount: totalDeposit, range: "Sheet1!A1")
        updateGoogleSheetWithData(amount: balance, range: "Sheet1!A2")
    }
    
    func signOut() {
        googleSignInManager.signOut()
    }
}
