//
//  FetchConfigrations.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation
import SwiftData

/// Configuration for data fetching in `ObservableDataRepositoryStore`.
///
/// This struct encapsulates all the parameters needed to configure how data is fetched
/// and kept in sync in an observable data store. It's used by `ObservableDataRepositoryStore` to
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
/// // Use with ObservableDataRepositoryStore
/// let store = ObservableDataRepositoryStore<Todo>(
///     fetchConfiguration: priorityConfig
/// )
/// ```
///
/// - Note: This configuration is immutable once set in `ObservableDataRepositoryStore`.
///         The store's `fetchConfiguration` property is marked as `let`.
///
public struct FetchConfigrations<Model: PersistentModel> {

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
    public let sortDescriptors: [SortDescriptor<Model>]

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
    public let predicate: Predicate<Model>?

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
    public let propertiesToFetch: PropertiesOption<Model>

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
    public let relationshipKeyPathsForPrefetching: [PartialKeyPath<Model>]?

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
    public let fetchOptions: FetchOptions

    /// Initializes a new fetch configuration.
    ///
    /// - Parameters:
    ///   - sortDescriptors: Sort descriptors for ordering results
    ///   - predicate: Optional predicate for filtering results
    ///   - propertiesToFetch: Properties to fetch (default: all)
    ///   - relationshipKeyPathsForPrefetching: Relationships to prefetch (default: nil)
    ///   - fetchOptions: Pagination options (default: all)
    public init(
        sortDescriptors: [SortDescriptor<Model>] = [],
        predicate: Predicate<Model>? = nil,
        propertiesToFetch: PropertiesOption<Model> = .all,
        relationshipKeyPathsForPrefetching: [PartialKeyPath<Model>]? = nil,
        fetchOptions: FetchOptions = .all
    ) {
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.propertiesToFetch = propertiesToFetch
        self.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
        self.fetchOptions = fetchOptions
    }
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
    /// let store = ObservableDataRepositoryStore<Todo>(
    ///     fetchConfiguration: .default
    /// )
    /// ```
    ///
    /// - Note: Marked as `nonisolated` to allow usage from any isolation context,
    ///         including as a default parameter value.
    public nonisolated static var `default`: Self {
        Self(
            sortDescriptors: [],
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions: .all
        )
    }
}
