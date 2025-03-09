//
//  GoogleSheetsService.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn
import CoreData

// Custom Error Enum for more specific error handling
enum GoogleSheetManagerError: LocalizedError {
    case userNotSignedIn
    case invalidToken
    case fetchDataFailed
    case updateDataFailed
    case missingData
    case missingManagerInfo
    
    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "User is not signed in."
        case .invalidToken:
            return "Invalid token provided."
        case .fetchDataFailed:
            return "Failed to fetch data from Google Sheets."
        case .updateDataFailed:
            return "Failed to update data on Google Sheets."
        case .missingData:
            return "Data is missing or invalid."
        case .missingManagerInfo:
            return "Manager information not found in the sheet."
        }
    }
}

class GoogleSheetManager {
    static let shared = GoogleSheetManager()
    private init() {}

    private let backendURL = "https://sheets.googleapis.com/v4/spreadsheets"
    private let spreadsheetId = "1gwb-6tOGu8F7CxwX3gGnEZFBHCoxi6cYnLOsZ-S5vPM"
    private let managerInfoRange = "ManagerInfo!A2:C"
    
    private var tokenString: String = ""
    private var userName = ""
    private var userEmail = ""
    
    @Published var managerRange: String = ""
    @Published var sheetValues: [[String]] = []
    
    private let googleSignInManager = GoogleSignInManager.shared

    
    // Initialization function
    func initialize(completion: @escaping (Result<String, Error>) -> Void) {
        // Ensure that GoogleSignInManager is available and signed in
        guard googleSignInManager.currentUser != nil else {
            completion(.failure(GoogleSheetManagerError.userNotSignedIn))
            return
        }

        // Authenticate the user
        authenticate { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                // Proceed with fetching manager information
                self.fetchManagerInfo { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        // Load sheet data after successful manager info fetch
                        self.loadSheetData { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                self.saveAccountDataToDatabase()
                                completion(.success("Initialization Completed!"))
                            }
                        }
                    }
                }
            }
        }
    }

    // Authenticates the user using Google Sign-In
    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
            // Ensure the user is signed in before proceeding
            guard let authentication = googleSignInManager.currentUser else {
                completion(.failure(GoogleSheetManagerError.userNotSignedIn))
                return
            }
            
            // Ensure the token is valid
            guard !authentication.accessToken.tokenString.isEmpty else {
                completion(.failure(GoogleSheetManagerError.invalidToken))
                return
            }
            
            // Store authentication details
            self.tokenString = authentication.accessToken.tokenString
            self.userName = authentication.profile?.name ?? "Unknown"
            self.userEmail = authentication.profile?.email ?? "unknown@example.com"
            completion(.success("User is Authenticated"))
        }
    
    // Fetch manager range information from Google Sheets
    func fetchManagerInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(backendURL)/\(spreadsheetId)/values/\(managerInfoRange)") else {
            completion(.failure(GoogleSheetManagerError.missingManagerInfo))
            return
        }
        
        // Create request with authentication
        let request = createRequest(url: url)
        
        // Fetch manager info
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GoogleSheetManagerError.missingData))
                return
            }
            
            do {
                // Decode response from Google Sheets API
                let decodedResponse = try JSONDecoder().decode(SheetResponse.self, from: data)
                
                // Look for the user's manager info
                for row in decodedResponse.values {
                    if row.count > 2, row[0] == self.userName, row[1] == self.userEmail {
                        self.managerRange = row[2]
                        completion(.success(()))
                        return
                    }
                }
                completion(.failure(GoogleSheetManagerError.missingManagerInfo))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Load sheet data for the fetched manager range
    func loadSheetData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(backendURL)/\(spreadsheetId)/values/\(managerRange)") else {
            completion(.failure(GoogleSheetManagerError.fetchDataFailed))
            return
        }
        
        let request = createRequest(url: url)
        
        // Fetch sheet data
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GoogleSheetManagerError.missingData))
                return
            }
            
            do {
                // Decode the response containing sheet values
                let decodedResponse = try JSONDecoder().decode(SheetResponse.self, from: data)
                self.sheetValues = decodedResponse.values
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Helper function to create URLRequest with authentication header
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // Helper function to save account data to Core Data
    func saveAccountDataToDatabase() {
        for accountData in self.sheetValues {
            let name = accountData[0]
            let totalDeposits = Double(accountData[1]) ?? 0
            let currentBalance = Double(accountData[2]) ?? 0
            CoreDataManager.shared.saveAccount(name: name, totalDeposits: totalDeposits, currentBalance: currentBalance)
        }
    }
    
    // Updates managers range in Google Sheets
    func updateSheetData(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(self.backendURL)/\(self.spreadsheetId)/values/\(self.managerRange)?valueInputOption=RAW") else {
            completion(.failure(GoogleSheetManagerError.updateDataFailed))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
        
        print(self.sheetValues)
        let parameters: [String: Any] = ["range": self.managerRange, "majorDimension": "ROWS", "values": self.sheetValues]
        
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
    
    // Function to write data to Google Sheets
    func writeData(values: [[String]]) {
        self.sheetValues = values
        self.sheetValues = self.sheetValues.filter { !$0.isEmpty }
        
        // Updating data in the sheet
        updateSheetData { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print("Error writing data to Google Sheets: \(error.localizedDescription)")
                case .success(let message):
                    print(message) // Successfully updated sheet
                }
            }
        }
    }

}

// Struct to parse Google Sheets API response
struct SheetResponse: Decodable {
    let values: [[String]]
}

