//
//  EditTodoView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import SwiftUI
import SwiftDataKit

struct EditTodoView: View {
    let todosStore: any DataRepository<Todo>
    let todo: Todo
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var priority: Priority
    @State private var isCompleted: Bool

    init(todosStore: any DataRepository<Todo>, todo: Todo, onSave: @escaping () -> Void) {
        self.todosStore = todosStore
        self.todo = todo
        self.onSave = onSave
        _title = State(initialValue: todo.title)
        _priority = State(initialValue: todo.priority)
        _isCompleted = State(initialValue: todo.isCompleted)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Todo Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(DefaultTextFieldStyle())

                    Picker("Priority", selection: $priority) {
                        Label("Low", systemImage: "arrow.down.circle")
                            .foregroundColor(.blue)
                            .tag(Priority.low)

                        Label("Medium", systemImage: "minus.circle")
                            .foregroundColor(.orange)
                            .tag(Priority.medium)

                        Label("High", systemImage: "arrow.up.circle")
                            .foregroundColor(.red)
                            .tag(Priority.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section("Status") {
                    Toggle(isOn: $isCompleted) {
                        Label(
                            "Completed",
                            systemImage: isCompleted ? "checkmark.circle.fill" : "circle"
                        )
                        .foregroundColor(isCompleted ? .green : .secondary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                }

                Section("Information") {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(todo.createdAt.relativeTime())
                            .foregroundColor(.secondary)
                    }

                    if isCompleted != todo.isCompleted {
                        HStack {
                            Label("Will be marked as", systemImage: "info.circle")
                            Spacer()
                            Text(isCompleted ? "Completed" : "Active")
                                .foregroundColor(isCompleted ? .green : .orange)
                                .fontWeight(.medium)
                        }
                    }
                }

                Section {
                    Button(action: deleteTodo) {
                        Label("Delete Todo", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Todo")
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
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func updateTodo() {
        do {
            try todosStore.update(todo) { item in
                item.title = title
                item.priority = priority
                item.isCompleted = isCompleted
            }
            onSave()
            dismiss()
        } catch {
            print("Error updating todo: \(error)")
        }
    }

    private func deleteTodo() {
        do {
            try todosStore.delete(todo)
            onSave()
            dismiss()
        } catch {
            print("Error deleting todo: \(error)")
        }
    }
}
