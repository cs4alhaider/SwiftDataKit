//
//  SettingsView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 29/09/2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Database", systemImage: "externaldrive")
                        Spacer()
                        Text("SwiftDataKit")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Data Access Methods") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("DataStore Approach", systemImage: "shippingbox")
                            .font(.headline)
                        Text("• Uses custom DataStore wrapper\n• Provides additional abstractions\n• Error handling with DataStoreError\n• Supports pagination and custom fetch options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Native SwiftUI Approach", systemImage: "swiftdata")
                            .font(.headline)
                        Text("• Uses @Query macro directly\n• Automatic view updates\n• Direct ModelContext access\n• Simpler for basic CRUD operations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                    .padding(.vertical, 4)
                }

                Section("Architecture") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Both approaches work because:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• SwiftDataKit.shared provides the ModelContainer\n• ModelContainer is injected at app level\n• Both views access the same data store\n• Changes in one view appear in the other")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("About") {
                    Label("Developer", systemImage: "person.circle")
                        .badge("Abdullah Alhaider")

                    Label("Built with", systemImage: "hammer")
                        .badge("SwiftUI & SwiftData")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}