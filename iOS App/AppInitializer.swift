//
//  AppInitializer.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/8/25.
//

import Foundation
import GoogleSignIn

class AppInitializer {
    static let shared = AppInitializer()

    private let googleSignInManager = GoogleSignInManager.shared
    private let googleSheetManager = GoogleSheetManager.shared

    private init() {}

    // This function can be used to initialize all necessary services
    func initialize(completion: @escaping (Result<String, Error>) -> Void) {
        
        if googleSignInManager.currentUser != nil {
            // If the user is signed in, proceed with initializing GoogleSheetManager
            googleSheetManager.initialize { result in
                switch result {
                case .failure(let error):
                    print("Error initializing GoogleSheetManager: \(error.localizedDescription)")
                    completion(.failure(error))
                case .success:
                    print("GoogleSheetManager initialized successfully")
                    completion(.success("App Initialized Successfully"))
                }
            }
        } else {
            // Handle the case where the user is not signed in
            print("❌ User is not signed in. Cannot initialize GoogleSheetManager.")
            completion(.failure(NSError(domain: "AppInitializerError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
        }
    }
}
