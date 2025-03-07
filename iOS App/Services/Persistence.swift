//
//  Persistence.swift
//  PickManager
//
//  Created by Brian Nguyen on 3/5/25.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PickManager")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Preview context for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true) // Use in-memory store for previews
        controller.createSampleData() // Optionally create some sample data
        return controller
    }()

    // MARK: - Function to create sample data for previews
    func createSampleData() {
        let context = container.viewContext
        
        // Create some sample deposits
        let deposit1 = Deposit(context: context)
        deposit1.amount = 100.0
        deposit1.timestamp = Date()

        let deposit2 = Deposit(context: context)
        deposit2.amount = 50.0
        deposit2.timestamp = Date().addingTimeInterval(-86400) // 1 day ago

        // Create a sample balance
        let balance1 = Balance(context: context)
        balance1.amount = 150.0
        balance1.timestamp = Date()

        // Save sample data to the context
        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
}

