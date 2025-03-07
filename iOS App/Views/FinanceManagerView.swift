//
//  FinanceManagerView.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import SwiftUI

struct FinanceManagerView: View {
    @StateObject private var viewModel = FinanceManagerViewModel()

    var body: some View {
        NavigationView {
            VStack {
                // Input field for deposits
                TextField("Enter deposit amount", text: $viewModel.depositAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Save Deposit") {
                    viewModel.saveDeposit()  // Call the ViewModel's method
                }
                .padding()
                
                // Input field for current balance
                TextField("Enter current balance", text: $viewModel.currentBalanceAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Save Balance") {
                    viewModel.saveBalance()  // Call the ViewModel's method
                }
                .padding()

                // Display deposits
                List(viewModel.deposits, id: \.self) { deposit in
                    VStack(alignment: .leading) {
                        Text("Amount: \(deposit.amount, specifier: "%.2f")")
                        if let timestamp = deposit.timestamp {
                            Text("Date: \(formattedDate(timestamp))")
                        } else {
                            Text("Date: N/A")
                        }
                    }
                }
                
                // Display Total Deposits
                Text("Total Deposits: \(viewModel.totalDeposit, specifier: "%.2f")")
                    .padding(.top)
                
                // Display balance
                Text("Current Balance: \(viewModel.balance, specifier: "%.2f")")
                    .padding(.top)
                
                // Reset data button
                Button("Reset All Data") {
                    viewModel.resetAllData()
                }
                .padding(.top)
                .foregroundColor(.red)

                // Sign-out button
                Button("Sign Out") {
                    viewModel.signOut()
                }
                .padding()
                .foregroundColor(.red)
                
                // Display Sheet Update Status
                if let sheetUpdateStatus = viewModel.sheetUpdateStatus {
                    Text(sheetUpdateStatus)
                        .foregroundColor(sheetUpdateStatus.contains("success") ? .green : .red)
                        .padding()
                }

                
            }
            .onAppear {
                GoogleSignInManager.shared.restorePreviousSignIn()
                viewModel.loadData()
            }
            .navigationTitle("Empire Finance Manager")
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private func formattedDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}
