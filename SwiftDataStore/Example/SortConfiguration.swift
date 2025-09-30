//
//  SortConfiguration.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation
import SwiftData

// MARK: - Shared Sort Configuration

/// Shared sorting configuration used across all Todo views for consistency.
///
/// This ensures that all three view types (Native, Observable, and Manual DataRepositoryStore)
/// display todos in the same order.
///
/// ## Current Configuration
/// - Sort by: `createdAt` date
/// - Order: Reverse (newest first)
///
enum TodoSortConfiguration {
    /// Standard sort descriptors for Todo items - newest first
    static let standard: [SortDescriptor<Todo>] = [
        SortDescriptor(\.createdAt, order: .reverse)
    ]
}
