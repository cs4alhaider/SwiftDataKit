//
//  TodoListView.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import SwiftUI

struct TodoListView: View {
    @Environment(\.todos) private var todosStore
    @State private var todos: [Todo] = []
    @State private var showingAddSheet = false
    @State private var selectedTodo: Todo?

    var activeTodos: [Todo] {
        todos.filter { !$0.isCompleted }
    }

    var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                // Active Todos Section
                if !activeTodos.isEmpty {
                    Section("Active") {
                        ForEach(activeTodos, id: \.persistentModelID) { todo in
                            TodoRow(todo: todo, onToggle: {
                                toggleTodo(todo)
                            })
                            .onTapGesture {
                                selectedTodo = todo
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                        .onDelete(perform: deleteActiveTodos)
                    }
                }

                // Completed Todos Section
                if !completedTodos.isEmpty {
                    Section("Completed") {
                        ForEach(completedTodos, id: \.persistentModelID) { todo in
                            TodoRow(todo: todo, onToggle: {
                                toggleTodo(todo)
                            })
                            .opacity(0.6)
                            .onTapGesture {
                                selectedTodo = todo
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                        .onDelete(perform: deleteCompletedTodos)
                    }
                }

                // Empty State
                if todos.isEmpty {
                    ContentUnavailableView(
                        "No Todos",
                        systemImage: "checklist",
                        description: Text("Tap the + button to add your first todo")
                    )
                }
            }
            .animation(.default, value: todos)
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                loadTodos()
            }
            .refreshable {
                loadTodos()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTodoView(todosStore: todosStore) {
                    loadTodos()
                }
            }
            .sheet(item: $selectedTodo) { todo in
                EditTodoView(todosStore: todosStore, todo: todo) {
                    loadTodos()
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func loadTodos() {
        do {
            let now = Date.now
            todos = try todosStore.fetch(
                sortedBy: [SortDescriptor(\.createdAt, order: .reverse)],
                predicate: #Predicate { todo in
                    // todo.isCompleted == true
                    todo.createdAt < now
                },
                fetchOptions: .paging(offset: 0, limit: 100)
            )
        } catch {
            print("Error loading todos: \(error)")
        }
    }

    private func toggleTodo(_ todo: Todo) {
        do {
            try todosStore.update(todo) { item in
                item.isCompleted.toggle()
            }
//            loadTodos()
        } catch {
            print("Error updating todo: \(error)")
        }
    }

    private func deleteActiveTodos(at offsets: IndexSet) {
        let todosToDelete = offsets.map { activeTodos[$0] }

        for todo in todosToDelete {
            do {
                try todosStore.delete(todo)
                print("Deleted todo: \(todo.title)")
                loadTodos()
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
                print("Deleted completed todo: \(todo.title)")
                loadTodos()
            } catch {
                print("Error deleting completed todo '\(todo.title)': \(error)")
            }
        }
    }
}
