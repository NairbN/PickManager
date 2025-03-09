//
//  SignInViewModel.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/7/25.
//

import Foundation
import SwiftUI

class SignInViewModel: ObservableObject {
    private let googleSignInManager = GoogleSignInManager.shared
    @Published var isSignedIn = false  // Track if user is signed in
    
    // Flag to ensure restoreSignIn is only called once
    private var hasRestoredSignIn = false

    private let accountManager = CoreDataManager.shared  // Assuming you have this for account management

    func signIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            print("Unable to find root view controller")
            return
        }

        googleSignInManager.signIn(from: rootViewController) { result in
            switch result {
            case .success(let signInResult):
                print("User signed in: \(signInResult.user.profile?.name ?? "No name")")
                self.isSignedIn = true
            case .failure(let error):
                print("Sign-in failed: \(error.localizedDescription)")
            }
        }
    }

    func restoreSignIn() {
        // Avoid multiple calls to restoreSignIn
        if hasRestoredSignIn { return }
        
        hasRestoredSignIn = true
        
        googleSignInManager.restorePreviousSignIn { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    print("Google Sign-In restored: \(user.profile?.name ?? "No name")")
                    self?.isSignedIn = true  // Update isSignedIn
                case .failure(let error):
                    print("Error restoring sign-in: \(error.localizedDescription)")
                    self?.isSignedIn = false  // Ensure it is false if no user is found
                }
            }
        }
    }
}





