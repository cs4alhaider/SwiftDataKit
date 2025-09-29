//
//  SwiftDataStoreApp.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import SwiftUI
import SwiftData

@main
struct SwiftDataStoreApp: App {

    init() {
        do {
            try SwiftDataKit.configure(
                for: Todo.self,
                config: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to configure SwiftDataKit: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(SwiftDataKit.shared.modelContainer)
        }
    }
}
