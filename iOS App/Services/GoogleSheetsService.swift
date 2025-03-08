//
//  GoogleSheetsService.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn
import CoreData

class GoogleSheetManager {
    
    private let backendURL = "https://sheets.googleapis.com/v4/spreadsheets"
    private let spreadsheetId = "1gwb-6tOGu8F7CxwX3gGnEZFBHCoxi6cYnLOsZ-S5vPM"
    
    @Published var managerRange: String = ""
    
    /// Fetches data from Google Sheets for a given range
    func fetchSheetData(range: String, authentication: GIDGoogleUser, completion: @escaping (Result<[[String]], Error>) -> Void) {
        
        guard let url = URL(string: "\(backendURL)/\(spreadsheetId)/values/\(range)"),
              !authentication.accessToken.tokenString.isEmpty else {
            completion(.failure(NSError(domain: "GoogleSheetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL or missing token"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authentication.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GoogleSheetManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(SheetResponse.self, from: data)
                completion(.success(decodedResponse.values))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Updates a specific range in Google Sheets
    func updateSheetData(range: String, values: [[String]], authentication: GIDGoogleUser, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let url = URL(string: "\(backendURL)/\(spreadsheetId)/values/\(range)?valueInputOption=RAW"),
              !authentication.accessToken.tokenString.isEmpty else {
            completion(.failure(NSError(domain: "GoogleSheetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL or missing token"])))
            return
        }
        
        let parameters: [String: Any] = ["range": range, "majorDimension": "ROWS", "values": values]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authentication.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success("Successfully updated sheet"))
        }.resume()
    }
    
    /// Searches for a user's name and email in a Google Sheet and returns the adjacent manager info.
    func getManagerRange(authentication: GIDGoogleUser, completion: @escaping (Result<String, Error>) -> Void) {
        
        fetchSheetData(range: "ManagerInfo!A2:C", authentication: authentication) { result in
            switch result {
            case .success(let values):
                let userName = authentication.profile?.name ?? ""
                let userEmail = authentication.profile?.email ?? ""
                
                // Check each row to find the matching name and email
                for row in values {
                    if row.count > 2, row[0] == userName, row[1] == userEmail {
                        self.managerRange = row[2]
                        completion(.success(row[2]))
                        return
                    }
                }
                
                // If no match was found, return an error
                completion(.failure(NSError(domain: "GoogleSheetManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Manager info not found"])))
                
            case .failure(let error):
                completion(.failure(error)) // Return any error from fetching the sheet
            }
        }
    }
    

    /// Helper function to save account data to Core Data
    func saveAccountDataToDatabase(authentication: GIDGoogleUser,accounts: [[String]]) {
        // Loop through the data and save each account to Core Data
        for accountData in accounts {
            let name = accountData[0]
            let totalDeposits =  Double(accountData[1]) ?? 0
            let currentBalance = Double(accountData[2]) ?? 0
            let accountRange = accountData[3]
            
            CoreDataManager.shared.saveAccount(name: name, totalDeposits: totalDeposits, currentBalance: currentBalance, accountRange: accountRange)
        }
    }
    
    /// Fetches the manager info and then fetches the account data to save it to Core Data
    func fetchAndSaveManagerAccountData(authentication: GIDGoogleUser, completion: @escaping (Result<String, Error>) -> Void) {
        
        getManagerRange(authentication: authentication) { result in
            switch result {
            case .success(let range):
                // Use the manager's range to fetch account data
                self.fetchSheetData(range: range, authentication: authentication) { fetchResult in
                    switch fetchResult {
                    case .success(let values):
                        print(values)
                        // Call the function to save data to Core Data
                        self.saveAccountDataToDatabase(authentication: authentication,accounts: values)
                        completion(.success("Successfully saved manager account range data to database"))
                    case .failure(let error):
                        // Handle the error in fetching account data
                        completion(.failure(NSError(domain: "GoogleSheetManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error fetching account data: \(error.localizedDescription)"])))
                    }
                }
            case .failure(let error):
                // Handle the error in getting manager info
                completion(.failure(NSError(domain: "GoogleSheetManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error fetching manager info: \(error.localizedDescription)"])))
            }
        }
    }
    
}

// Struct to parse Google Sheets API response
struct SheetResponse: Decodable {
    let values: [[String]]
}



