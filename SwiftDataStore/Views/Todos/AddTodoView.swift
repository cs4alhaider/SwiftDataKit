//
//  AddTodoView.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import SwiftUI

struct AddTodoView: View {
    let todosStore: any StoreProtocol<Todo>
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var priority = Priority.medium

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

                Section("Information") {
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text("Now")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Todo")
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
        do {
            try todosStore.create(newTodo)
            onSave()
            dismiss()
        } catch {
            print("Error creating todo: \(error)")
        }
    }
}
