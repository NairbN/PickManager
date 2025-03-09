//
//  SignInView.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/7/25.
//
import Foundation
import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isSignedIn {
                    FinanceManagerView()
                } else {
                    Button("Sign In with Google") {
                        viewModel.signIn()
                    }
                    .padding()

                    if viewModel.isSignedIn == false {
                        ProgressView("Restoring sign-in...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                }
            }
            .onAppear() {
                viewModel.restoreSignIn()
            }
        }
    }
}




