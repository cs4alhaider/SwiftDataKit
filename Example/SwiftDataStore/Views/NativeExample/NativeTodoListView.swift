//
//  NativeTodoListView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 29/09/2025.
//

import SwiftData
import SwiftUI
import SwiftDataKit

/// This view demonstrates using native SwiftUI @Query to fetch todos
/// instead of using the DataStore. Both approaches work because we've
/// injected the modelContainer at the app level.
struct NativeTodoListView: View {
    // Using native SwiftUI @Query macro to fetch todos
    // This automatically observes changes and updates the view
    @Query(sort: \Todo.createdAt, order: .reverse) private var todos: [Todo]

    // Direct access to ModelContext from environment
    @Environment(\.modelContext) private var modelContext: ModelContext

    @State private var showingAddSheet: Bool = false
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
                if todos.isEmpty {
                    ContentUnavailableView(
                        "No Todos",
                        systemImage: "checklist",
                        description: Text("Tap the + button to add your first todo")
                    )
                }
            }
            .animation(.default, value: todos)
            .navigationTitle("Native SwiftUI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(todos.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NativeAddTodoView(modelContext: modelContext)
            }
            .sheet(item: $selectedTodo) { todo in
                NativeEditTodoView(todo: todo, modelContext: modelContext)
            }
            .overlay(alignment: .bottom) {
                // Info banner showing this uses native SwiftUI
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Using @Query & ModelContext")
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
        todo.isCompleted.toggle()

        do {
            try modelContext.save()
        } catch {
            print("Error toggling todo: \(error)")
        }
    }

    // MARK: - Delete Functions

    private func deleteActiveTodos(at offsets: IndexSet) {
        for index: IndexSet.Element in offsets {
            let todo = activeTodos[index]
            modelContext.delete(todo)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting todos: \(error)")
        }
    }

    private func deleteCompletedTodos(at offsets: IndexSet) {
        for index: IndexSet.Element in offsets {
            let todo = completedTodos[index]
            modelContext.delete(todo)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting completed todos: \(error)")
        }
    }
}

// MARK: - Native Add Todo View

struct NativeAddTodoView: View {
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var title: String = ""
    @State private var priority = Priority.medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Todo Details") {
                    TextField("Title", text: $title)

                    Picker("Priority", selection: $priority) {
                        Label("Low", systemImage: "arrow.down.circle")
                            .tag(Priority.low)
                        Label("Medium", systemImage: "minus.circle")
                            .tag(Priority.medium)
                        Label("High", systemImage: "arrow.up.circle")
                            .tag(Priority.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Text("This form uses native ModelContext to save")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Todo (Native)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTodo()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTodo() {
        let newTodo = Todo(title: title, priority: priority)
        modelContext.insert(newTodo)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving todo: \(error)")
        }
    }
}

// MARK: - Native Edit Todo View

struct NativeEditTodoView: View {
    @Bindable var todo: Todo
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var priority: Priority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Todo Details") {
                    TextField("Title", text: $title)

                    Picker("Priority", selection: $priority) {
                        Label("Low", systemImage: "arrow.down.circle")
                            .tag(Priority.low)
                        Label("Medium", systemImage: "minus.circle")
                            .tag(Priority.medium)
                        Label("High", systemImage: "arrow.up.circle")
                            .tag(Priority.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Completed", isOn: $todo.isCompleted)
                }

                Section("Information") {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(todo.createdAt.relativeTime())
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text("Editing with native ModelContext")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Todo (Native)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTodo()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            title = todo.title
            priority = todo.priority
        }
    }

    private func updateTodo() {
        todo.title = title
        todo.priority = priority

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error updating todo: \(error)")
        }
    }
}

#Preview {
    NativeTodoListView()
        .modelContainer(for: Todo.self, inMemory: true)
}
