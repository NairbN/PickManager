//
//  GoogleSignInService.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

import Foundation
import GoogleSignIn

class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    private let sheetManager = GoogleSheetManager()

    @Published var currentUser: GIDGoogleUser?

    // Restore the previous sign-in session
    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { signInResult, error in
            if let error = error {
                print("Google Sign-In restore failed: \(error.localizedDescription)")
                self.currentUser = nil
            } else if let signInResult = signInResult {
                self.currentUser = signInResult
                self.loadAccountData(user: signInResult)
                print("Google Sign-In restored: \(signInResult.profile?.name ?? "No Name")")
            }
        }
    }

    func signIn(from viewController: UIViewController, completion: @escaping (Result<GIDSignInResult, Error>) -> Void) {
        let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController, hint: nil, additionalScopes: additionalScopes) { signInResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let signInResult = signInResult {
                DispatchQueue.main.async {
                    self.currentUser = signInResult.user
                    self.loadAccountData(user: signInResult.user)
                }
                completion(.success(signInResult))
            } else {
                completion(.failure(NSError(domain: "GoogleSignInManager", code: 100, userInfo: [NSLocalizedDescriptionKey: "Unknown sign-in error"])))
            }
        }
    }

    // Sign out the user
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
        }
    }
    
    func loadAccountData(user: GIDGoogleUser) {
        sheetManager.fetchAndSaveManagerAccountData(authentication: user) { result in
            switch result {
            case .success(let message):
                print(message)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}




