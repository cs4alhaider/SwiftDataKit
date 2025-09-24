//
//  Todo.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

enum Priority: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
    
    var text: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

@Model
final class Todo: Identifiable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date

    init(title: String, isCompleted: Bool = false, priority: Priority = .medium) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = Date()
    }
}
