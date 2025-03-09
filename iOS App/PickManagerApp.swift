//
//  PickManagerApp.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//

import SwiftUI

@main
struct PickManagerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var googleSignInManager = GoogleSignInManager.shared
    
    // Keep track of sign-in state
    @State private var isAppInitialized = false
    @State private var initializationError: Error? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                SignInView()
            }
        }
    }
}





