//
//  SwiftDataStoreApp.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import SwiftUI
import SwiftData

@main
struct SwiftDataStoreApp: App {

    init() {
        do {
            try SwiftDataDB.configure(
                for: Todo.self,
                config: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to configure SwiftDataDB: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(SwiftDataDB.shared.modelContainer)
        }
    }
}
