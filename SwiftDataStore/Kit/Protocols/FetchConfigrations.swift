//
//  FetchConfigrations.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation
import SwiftData

// MARK: - FetchConfigrations

/// Configuration for data fetching in `ObservableDataStore`.
///
/// This struct encapsulates all the parameters needed to configure how data is fetched
/// and kept in sync in an observable data store. It's used by `ObservableDataStore` to
/// determine sorting, filtering, property selection, and pagination behavior.
///
/// ## Overview
///
/// `FetchConfigrations` provides a type-safe way to configure data fetching behavior,
/// including:
/// - Sorting criteria with multiple sort descriptors
/// - Filtering with predicates
/// - Selective property loading for performance optimization
/// - Relationship prefetching to avoid N+1 queries
/// - Pagination support for large datasets
///
/// ## Usage Example
///
/// ```swift
/// // Basic configuration with default values
/// let config = FetchConfigrations<Todo>.default
///
/// // Custom configuration for high-priority todos
/// let priorityConfig = FetchConfigrations<Todo>(
///     sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
///     predicate: #Predicate { $0.priority == .high },
///     propertiesToFetch: .all,
///     relationshipKeyPathsForPrefetching: nil,
///     fetchOptions: .paging(offset: 0, limit: 50)
/// )
///
/// // Use with ObservableDataStore
/// let store = ObservableDataStore<Todo>(
///     fetchConfiguration: priorityConfig
/// )
/// ```
///
/// - Note: This configuration is immutable once set in `ObservableDataStore`.
///         The store's `fetchConfiguration` property is marked as `let`.
///
struct FetchConfigrations<Model: PersistentModel> {

    /// Sort descriptors defining the order of fetched items.
    ///
    /// Multiple descriptors can be provided to sort by multiple criteria.
    /// Empty array means no specific sorting order.
    ///
    /// Example:
    /// ```swift
    /// [
    ///     SortDescriptor(\.priority, order: .forward),
    ///     SortDescriptor(\.createdAt, order: .reverse)
    /// ]
    /// ```
    let sortDescriptors: [SortDescriptor<Model>]

    /// Optional predicate to filter the fetched items.
    ///
    /// Use Swift's `#Predicate` macro to define filtering criteria.
    /// If `nil`, all items of the model type are fetched.
    ///
    /// Example:
    /// ```swift
    /// #Predicate<Todo> { todo in
    ///     !todo.isCompleted && todo.priority == .high
    /// }
    /// ```
    let predicate: Predicate<Model>?

    /// Specifies which properties to fetch from the model.
    ///
    /// Use `.all` to fetch all properties, or `.custom([keyPaths])` to fetch
    /// only specific properties for performance optimization.
    ///
    /// Example:
    /// ```swift
    /// .custom([\Todo.title, \Todo.isCompleted])
    /// ```
    ///
    /// - SeeAlso: `PropertiesOption`
    let propertiesToFetch: PropertiesOption<Model>

    /// Relationship key paths to prefetch along with the main fetch.
    ///
    /// By default, SwiftData lazily loads relationships. Specifying key paths here
    /// allows SwiftData to batch-fetch related objects, improving performance when
    /// you know you'll need those relationships.
    ///
    /// Example:
    /// ```swift
    /// [\Todo.category, \Todo.tags]
    /// ```
    ///
    /// - Note: This can significantly improve performance but also increase
    ///         memory usage if relationships are large.
    ///
    /// - SeeAlso: [SwiftData FetchDescriptor Documentation](https://developer.apple.com/documentation/swiftdata/fetchdescriptor/relationshipkeypathsforprefetching)
    let relationshipKeyPathsForPrefetching: [PartialKeyPath<Model>]?

    /// Fetch options controlling pagination behavior.
    ///
    /// Use `.all` to fetch all matching items, or `.paging(offset:limit:)` to
    /// implement pagination for large datasets.
    ///
    /// Example:
    /// ```swift
    /// .paging(offset: 0, limit: 20)
    /// ```
    ///
    /// - SeeAlso: `FetchOptions`
    let fetchOptions: FetchOptions
}

// MARK: - Default Configuration

extension FetchConfigrations {

    /// Default fetch configuration with sensible defaults.
    ///
    /// This configuration fetches all items with:
    /// - No sorting (natural order)
    /// - No filtering (all items)
    /// - All properties fetched
    /// - No relationship prefetching
    /// - No pagination (all items)
    ///
    /// Use this as a starting point when you don't need specific fetch behavior.
    ///
    /// Example:
    /// ```swift
    /// let store = ObservableDataStore<Todo>(
    ///     fetchConfiguration: .default
    /// )
    /// ```
    ///
    /// - Note: Marked as `nonisolated` to allow usage from any isolation context,
    ///         including as a default parameter value.
    nonisolated static var `default`: Self {
        Self(
            sortDescriptors: [],
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions: .all
        )
    }
}
