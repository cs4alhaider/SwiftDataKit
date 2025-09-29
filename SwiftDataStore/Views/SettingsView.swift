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