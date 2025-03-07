//
//  PickManagerApp.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//

import SwiftUI
import GoogleSignIn

@main
struct PickManagerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var googleSignInManager = GoogleSignInManager.shared
    
    // Keep track of sign-in state

    var body: some Scene {
        WindowGroup {
            Group {
                if googleSignInManager.currentUser != nil {
                    FinanceManagerView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    SignInView()
                        .onAppear {
                            googleSignInManager.restorePreviousSignIn()  // Restore sign-in on launch
                        }
                }
            }
        }
    }
}




