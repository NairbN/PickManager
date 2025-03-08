//
//  SignInViewModel.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/7/25.
//

import Foundation
import SwiftUI

class SignInViewModel: ObservableObject {
    private let googleSignInManager = GoogleSignInManager()
    @Published var isSignedIn = false  // Track if user is signed in
    
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
        // Restoring sign-in status without a closure
        googleSignInManager.restorePreviousSignIn()
        
        if let currentUser = googleSignInManager.currentUser {
            print("Google Sign-In restored: \(currentUser.profile?.name ?? "No name")")
            self.isSignedIn = true
        } else {
            print("Error restoring sign-in: No user found.")
        }
    }


    

}



