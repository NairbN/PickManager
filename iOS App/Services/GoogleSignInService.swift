//
//  GoogleSignInService.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/6/25.
//

// GoogleSignInService.swift
import Foundation
import GoogleSignIn

class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    private init() {}
    
    @Published var currentUser: GIDGoogleUser?

    // Restore the previous sign-in session
    func restorePreviousSignIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] signInResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("Google Sign-In restore failed: \(error.localizedDescription)")
                    self.currentUser = nil
                    completion(.failure(error))  // Notify completion with failure
                } else if let signInResult = signInResult {
                    self.currentUser = signInResult
                    print("Google Sign-In restored: \(signInResult.profile?.name ?? "No Name")")
                    completion(.success(signInResult))  // Notify completion with success
                } else {
                    self.currentUser = nil
                    print("No previous sign-in found.")
                    completion(.failure(NSError(domain: "GoogleSignInManager", code: 101, userInfo: [NSLocalizedDescriptionKey: "No previous sign-in found"])))
                }
            }
        }
    }

    // Perform sign-in process
    func signIn(from viewController: UIViewController, completion: @escaping (Result<GIDSignInResult, Error>) -> Void) {
        let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController, hint: nil, additionalScopes: additionalScopes) { [weak self] signInResult, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let signInResult = signInResult else {
                let unknownError = NSError(domain: "GoogleSignInManager", code: 100, userInfo: [NSLocalizedDescriptionKey: "Unknown sign-in error"])
                completion(.failure(unknownError))
                return
            }

            DispatchQueue.main.async {
                self.currentUser = signInResult.user
            }
            completion(.success(signInResult))
        }
    }

    // Sign out the user
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
        }
    }
}


