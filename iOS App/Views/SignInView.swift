//
//  SignInView.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/7/25.
//
import Foundation
import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @StateObject private var googleSignInManager = GoogleSignInManager()
    @State private var isSignedIn = false  // Track if user is signed in

    var body: some View {
        NavigationStack {
            VStack {
                if let currentUser = googleSignInManager.currentUser {
                    if isSignedIn {
                        FinanceManagerView()
                    }
                } else {
                    // User is not signed in, show the Sign-In button
                    Button("Sign In with Google") {
                        signInWithGoogle()
                    }
                    .padding()
                }
            }
            .onAppear {
                googleSignInManager.restorePreviousSignIn()
            }
        }
    }

    private func signInWithGoogle() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            print("Unable to find root view controller")
            return
        }

        googleSignInManager.signIn(from: rootViewController) { result in
            switch result {
            case .success(let signInResult):
                print("User signed in: \(signInResult.user.profile?.name ?? "No name")")
                // Set isSignedIn to true when sign-in is successful
                DispatchQueue.main.async {
                    isSignedIn = true
                }
            case .failure(let error):
                print("Sign-in failed: \(error.localizedDescription)")
            }
        }
    }
}



