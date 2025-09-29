//
//  ContentView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodoListView()
                .tabItem {
                    Label("DataStore", systemImage: "shippingbox")
                }
                .tag(0)

            NativeTodoListView()
                .tabItem {
                    Label("Native", systemImage: "swiftdata")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
