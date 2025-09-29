//
//  NativeTodoListView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 29/09/2025.
//

import SwiftUI
import SwiftData

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
                    Section("Active") {
                        ForEach(activeTodos) { todo in
                            NativeTodoRow(todo: todo, modelContext: modelContext)
                                .onTapGesture {
                                    selectedTodo = todo
                                }
                        }
                        .onDelete(perform: deleteActiveTodos)
                    }
                }

                // Completed Todos Section
                if !completedTodos.isEmpty {
                    Section("Completed") {
                        ForEach(completedTodos) { todo in
                            NativeTodoRow(todo: todo, modelContext: modelContext)
                                .opacity(0.6)
                                .onTapGesture {
                                    selectedTodo = todo
                                }
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
            .navigationTitle("Native SwiftUI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
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

    // MARK: - Delete Functions using Native ModelContext

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

// MARK: - Native Todo Row

struct NativeTodoRow: View {
    let todo: Todo
    let modelContext: ModelContext

    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(todo.priority.text, systemImage: todo.priority.icon)
                        .font(.caption)
                        .foregroundColor(todo.priority.color)

                    Text(todo.createdAt.relativeTime())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func toggleCompletion() {
        todo.isCompleted.toggle()

        do {
            try modelContext.save()
        } catch {
            print("Error toggling todo: \(error)")
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