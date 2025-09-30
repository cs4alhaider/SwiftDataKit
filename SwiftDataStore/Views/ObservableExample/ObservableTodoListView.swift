//
//  ObservableTodoListView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 29/09/2025.
//

import SwiftUI

/// This view demonstrates using the DataStore with auto-fetch enabled.
/// The todos are automatically kept in sync through the items property.
struct ObservableTodoListView: View {
    @Environment(\.observableTodos) private var todosStore: ObservableDataStore<Todo>
    @State private var showingAddSheet = false
    @State private var selectedTodo: Todo?

    var activeTodos: [Todo] {
        todosStore.items.filter { !$0.isCompleted }
    }

    var completedTodos: [Todo] {
        todosStore.items.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                // Active Todos Section
                if !activeTodos.isEmpty {
                    Section("Active (\(activeTodos.count))") {
                        ForEach(activeTodos, id: \.persistentModelID) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: {
                                    toggleTodo(todo)
                                }
                            )
                            .onTapGesture {
                                selectedTodo = todo
                            }
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }
                        .onDelete(perform: deleteActiveTodos)
                    }
                }

                // Completed Todos Section
                if !completedTodos.isEmpty {
                    Section("Completed (\(completedTodos.count))") {
                        ForEach(completedTodos, id: \.persistentModelID) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: {
                                    toggleTodo(todo)
                                }
                            )
                            .opacity(0.6)
                            .onTapGesture {
                                selectedTodo = todo
                            }
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }
                        .onDelete(perform: deleteCompletedTodos)
                    }
                }

                // Empty State
                if todosStore.items.isEmpty {
                    ContentUnavailableView(
                        "No Todos",
                        systemImage: "checklist",
                        description: Text("Tap the + button to add your first todo")
                    )
                }
            }
            .animation(.default, value: todosStore.items)
            .navigationTitle("Observable Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Total: \(todosStore.items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTodoView(todosStore: todosStore) {
                    // No need to reload - items auto-update
                }
            }
            .sheet(item: $selectedTodo) { todo in
                EditTodoView(todosStore: todosStore, todo: todo) {
                    // No need to reload - items auto-update
                }
            }
            .overlay(alignment: .bottom) {
                // Info banner showing this uses Observable DataStore
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(.green)
                    Text("Auto-synced via Observable")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Helper Functions

    private func toggleTodo(_ todo: Todo) {
        do {
            try todosStore.update(todo) { item in
                item.isCompleted.toggle()
            }
            // Items will auto-update via notifications
        } catch {
            print("Error updating todo: \(error)")
        }
    }

    private func deleteActiveTodos(at offsets: IndexSet) {
        let todosToDelete = offsets.map { activeTodos[$0] }

        for todo in todosToDelete {
            do {
                try todosStore.delete(todo)
                // Items will auto-update via notifications
            } catch {
                print("Error deleting todo '\(todo.title)': \(error)")
            }
        }
    }

    private func deleteCompletedTodos(at offsets: IndexSet) {
        let todosToDelete = offsets.map { completedTodos[$0] }

        for todo in todosToDelete {
            do {
                try todosStore.delete(todo)
                // Items will auto-update via notifications
            } catch {
                print("Error deleting completed todo '\(todo.title)': \(error)")
            }
        }
    }
}

#Preview {
    ObservableTodoListView()
}
