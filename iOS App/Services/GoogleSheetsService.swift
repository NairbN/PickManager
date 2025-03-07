//
//  GoogleSheetsService.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn

class GoogleSheetManager {

    private let backendURL = "https://sheets.googleapis.com/v4/spreadsheets"
    private let spreadsheetId = "1gwb-6tOGu8F7CxwX3gGnEZFBHCoxi6cYnLOsZ-S5vPM"

    // Function to create URL Request and Update Google Sheet
    func updateGoogleSheet(range: String, values: [[String]], authentication: GIDGoogleUser, completion: @escaping (Result<String, Error>) -> Void) {
        
        // Extract the access token from the authentication object
        let accessToken = authentication.accessToken.tokenString // Directly access tokenString, no need for optional binding

        // Check if the accessToken exists (optional check as precaution, but tokenString is non-optional)
        if accessToken.isEmpty {
            completion(.failure(NSError(domain: "GoogleSheetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Access token is empty"])))
            return
        }

        // Parameters to send in the HTTP request
        let parameters: [String: Any] = [
            "range": range,
            "majorDimension": "ROWS",
            "values": values
        ]
        
        // Create the URL request for the Google Sheets API
        guard let url = URL(string: "\(backendURL)/\(spreadsheetId)/values/\(range)?valueInputOption=RAW") else {
            completion(.failure(NSError(domain: "GoogleSheetManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Convert parameters to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        // Perform the HTTP request using URLSession
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "GoogleSheetManager", code: 101, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            // Try to parse the response
            if (try? JSONSerialization.jsonObject(with: data, options: [])) != nil {
                completion(.success("Successfully updated sheet"))
            } else {
                completion(.failure(NSError(domain: "GoogleSheetManager", code: 102, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            }
            


        }

        task.resume()
    }
}



