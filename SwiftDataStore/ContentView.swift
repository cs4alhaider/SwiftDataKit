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
                    Label("Manual", systemImage: "hand.tap")
                }
                .tag(0)

            ObservableTodoListView()
                .tabItem {
                    Label("Observable", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(1)

            NativeTodoListView()
                .tabItem {
                    Label("Native", systemImage: "swiftdata")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
