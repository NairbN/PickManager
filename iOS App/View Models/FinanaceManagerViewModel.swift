//
//  FinanaceManagerViewModel.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn

class FinanceManagerViewModel: ObservableObject {
    public var account: Account? = nil
    public var deposits: [Deposit] = []
    public var balance: Double = 0.0
    public var totalDeposit: Double = 0.0
    @Published var depositAmount: String = ""
    @Published var currentBalanceAmount: String = ""
    
    @Published var sheetUpdateStatus: String? = nil  // Add status property

    private let sheetManager = GoogleSheetManager.shared
    private let googleSignInManager = GoogleSignInManager.shared  // Access GoogleSignInManager
    private var logCounter : Int = 1;
    
    
    func initialize(accountName: String){
        sheetManager.initialize(){ result in
            switch result{
            case .success(let message):
                print(message)
                self.setAccount(accountName: accountName)
            case .failure(let error):
                print(error)
                return
            }
        }
    }
    
    func updateSheet(){
        let values: [[String]] = CoreDataManager.shared.getTable()
        
        sheetManager.writeData(values: values)
    }
    
    func setAccount(accountName: String){
        if let account = CoreDataManager.shared.fetchAccountByName(name: accountName) {
            self.account = account
            self.loadAccountData()
        } else{
            print("❌ No account found in ViewModel")
            return
        }
    }

    func loadAccountData() {
        guard let account = self.account else { return }
        self.deposits = account.deposits?.allObjects as? [Deposit] ?? []
        self.balance = account.balance?.amount ?? 0.0
        self.totalDeposit = self.deposits.reduce(0) { $0 + $1.amount }
        
        depositAmount = ""
        currentBalanceAmount = ""
        
        updateSheet()

        print("✅ Loaded Account: \(account.name ?? "Unknown")")
        print("💰 Balance: \(balance), Total Deposits: \(totalDeposit)")
        print("📜 Deposits: \(deposits.map { "\($0.amount)" }.joined(separator: ", "))")
    }

    func saveDeposit() {
        guard let account = self.account else { return }
        if let amount = Double(depositAmount) {
            CoreDataManager.shared.saveDeposit(amount: amount, to: account)
            loadAccountData()  // Ensure totalDeposit is updated
            
            depositAmount = ""
        }
    }


    func saveBalance() {
        guard let account = self.account else { return }
        if let amount = Double(currentBalanceAmount) {
            CoreDataManager.shared.saveBalance(amount: amount, to: account)
            loadAccountData()

            currentBalanceAmount = ""

        }
    }

    
    func resetAccountData() {
        guard let account = self.account else { return }
        CoreDataManager.shared.resetAccountData(account: account)
        
        loadAccountData()
    }
    
    func signOut() {
        googleSignInManager.signOut()
    }
}
