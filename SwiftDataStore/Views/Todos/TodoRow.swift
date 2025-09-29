//
//  TodoRow.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void
    @State private var isAnimating: Bool = false

    var body: some View {
        HStack {
            // Checkbox
            ZStack {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .opacity(todo.isCompleted ? 0 : 1)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .scaleEffect(todo.isCompleted ? 1 : 0.001)
                    .opacity(todo.isCompleted ? 1 : 0)
            }
            .font(.title2)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isAnimating = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isAnimating = false
                    }
                }

                onToggle()
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted, color: .secondary)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.3), value: todo.isCompleted)

                HStack(spacing: 12) {
                    // Priority
                    Label(todo.priority.text, systemImage: todo.priority.icon)
                        .font(.caption)
                        .foregroundColor(todo.priority.color)

                    // Time
                    Label(todo.createdAt.relativeTime(), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
