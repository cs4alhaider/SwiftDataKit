//
//  ObservableDataStore.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 30/09/2025.
//

import Combine
import Foundation
import SwiftData

// MARK: - DataStore Implementation

/// A generic data store for managing persistent model objects using SwiftData.
///
/// `DataStore` provides a type-safe interface for CRUD operations on any `PersistentModel` type.
/// It uses the shared `SwiftDataKit` instance to access the underlying model context.
///
/// ## Overview
/// This class implements the `DataRepository` and provides methods for:
/// - Creating new items
/// - Fetching items with sorting, filtering, and pagination
/// - Updating existing items
/// - Deleting individual items or batches
///
/// ## Usage Example
/// ```swift
/// let todoStore = DataStore<Todo>()
///
/// // Create a new todo
/// let todo = Todo(title: "Buy groceries")
/// try todoStore.create(todo)
///
/// // Fetch todos with filtering
/// let highPriorityTodos = try todoStore.fetch(
///     sortedBy: [SortDescriptor(\.createdAt, order: .reverse)],
///     predicate: #Predicate { $0.priority == .high }
/// )
/// ```
///
/// ## Thread Safety
/// This class is marked with `@MainActor` to ensure all operations happen on the main thread.
/// For background operations, use `SwiftDataKit.shared.newBackgroundContext()`.
///
@MainActor
public final class ObservableDataStore<T>: ObservableObject, ObservableDataRepository
where T: PersistentModel {

    // MARK: - Public Properties

    /// The current items in the store, automatically updated when the ModelContext changes
    @Published public internal(set) var items: [T] = []

    // MARK: - Private Properties

    /// The model context used for all data operations.
    /// This context is obtained from the shared SwiftDataKit instance.
    private let modelContext: ModelContext

    /// Cancellables for Combine subscriptions
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    /// Current fetch configuration for auto-fetching
    private let fetchConfiguration: FetchConfigrations<T>

    // MARK: - Initialization

    /// Initializes a new DataStore instance.
    ///
    /// The store automatically uses the shared SwiftDataKit's model context,
    /// which must be configured before creating any DataStore instances.
    ///
    /// - Parameters:
    ///   - modelContext: Optional custom ModelContext. If nil, uses SwiftDataKit.shared.modelContext
    ///   - fetchConfiguration: Configuration for automatic fetching and updates
    ///
    /// - Note: Ensure `SwiftDataKit.configure()` has been called at app startup
    ///         before creating DataStore instances.
    public init(
        modelContext: ModelContext? = nil, fetchConfiguration: FetchConfigrations<T> = .default
    ) {
        self.modelContext = modelContext ?? SwiftDataKit.shared.modelContext
        self.fetchConfiguration = fetchConfiguration

        // Setup notification listeners
        setupNotificationListeners()

        // Perform initial fetch
        do {
            self.items = try fetch(
                sortedBy: fetchConfiguration.sortDescriptors,
                predicate: fetchConfiguration.predicate,
                propertiesToFetch: fetchConfiguration.propertiesToFetch,
                relationshipKeyPathsForPrefetching: fetchConfiguration
                    .relationshipKeyPathsForPrefetching,
                fetchOptions: fetchConfiguration.fetchOptions
            )
        } catch {
            print("Error performing initial fetch: \(error)")
            self.items = []
        }
    }

    // No need for explicit deinit - AnyCancellable automatically cancels when deallocated

    // MARK: - Private Methods

    /// Sets up notification listeners for ModelContext changes
    private func setupNotificationListeners() {
        // Listen for ModelContext.didSave notifications
        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleModelContextDidSave(notification)
            }
            .store(in: &cancellables)
    }

    /// Handles ModelContext.didSave notifications
    private func handleModelContextDidSave(_ notification: Notification) {
        // Accept notifications from any ModelContext since we're using a shared container
        // This ensures updates from Native view are reflected here
        guard notification.object is ModelContext else { return }

        // Always re-fetch when any save occurs to keep items in sync
        // This ensures we catch all updates, even when userInfo is incomplete
        performAutoFetch()
    }

    /// Performs automatic fetch based on current configuration
    private func performAutoFetch() {
        do {
            // Directly fetch from context to avoid recursion
            var fetchRequest: FetchDescriptor<T> = FetchDescriptor<T>(
                predicate: fetchConfiguration.predicate,
                sortBy: fetchConfiguration.sortDescriptors
            )

            if case .paging(let offset, let limit) = fetchConfiguration.fetchOptions {
                fetchRequest.fetchOffset = offset
                fetchRequest.fetchLimit = limit
            }

            if case .custom(let properties) = fetchConfiguration.propertiesToFetch {
                fetchRequest.propertiesToFetch = properties
            }

            if let relationshipKeyPathsForPrefetching = fetchConfiguration
                .relationshipKeyPathsForPrefetching
            {
                fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
            }

            // Fetch and update items
            let fetchedItems = try modelContext.fetch(fetchRequest)
            self.items = fetchedItems
        } catch {
            print("Error performing auto-fetch: \(error)")
        }
    }

    // MARK: - Public Methods - Create

    /// Creates a new item in the persistent store.
    ///
    /// This method inserts the item into the model context and immediately saves it.
    /// If autosave is enabled on the context, the save happens automatically.
    ///
    /// - Parameter item: The model object to be created.
    ///
    /// - Throws: An error if the create operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let newTodo = Todo(title: "Write documentation")
    ///   try todoStore.create(newTodo)
    ///   ```
    public func create(_ item: T) throws {
        modelContext.insert(item)
        try modelContext.save()
        // The didSave notification will trigger auto-fetch
    }

    // MARK: - Public Methods - Read

    /// Fetches items from the store with advanced querying options.
    ///
    /// This method provides comprehensive control over data fetching including:
    /// - Sorting by multiple criteria
    /// - Filtering with predicates
    /// - Selective property loading for performance
    /// - Relationship prefetching to avoid N+1 queries
    /// - Pagination support
    ///
    /// - Parameters:
    ///   - sortDescriptors: Array of sort descriptors to order results.
    ///                      Example: `[SortDescriptor(\.createdAt, order: .reverse)]`
    ///   - predicate: Optional predicate to filter results.
    ///               Example: `#Predicate { $0.isCompleted == false }`
    ///   - propertiesToFetch: Specifies which properties to load.
    ///                       Use `.all` for all properties or `.custom([keyPaths])` for specific ones.
    ///   - relationshipKeyPathsForPrefetching: Relationships to prefetch for performance.
    ///                                         Prevents lazy loading of relationships.
    ///   - fetchOptions: Controls result set size with `.all` or `.paging(offset:limit:)`
    ///
    /// - Returns: Array of model objects matching the criteria.
    ///
    /// - Throws: An error if the fetch operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let recentTodos = try todoStore.fetch(
    ///       sortedBy: [SortDescriptor(\.createdAt, order: .reverse)],
    ///       predicate: #Predicate { todo in
    ///           todo.createdAt > Date.now.addingTimeInterval(-86400)
    ///       },
    ///       fetchOptions: .paging(offset: 0, limit: 10)
    ///   )
    ///   ```
    ///
    /// - SeeAlso:
    ///   - https://developer.apple.com/documentation/swiftdata/fetchdescriptor
    ///   - https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-custom-fetchdescriptor
    public func fetch(
        sortedBy sortDescriptors: [SortDescriptor<T>] = [],
        predicate: Predicate<T>? = nil,
        propertiesToFetch: PropertiesOption<T> = .all,
        relationshipKeyPathsForPrefetching: [PartialKeyPath<T>]? = nil,
        fetchOptions: FetchOptions = .all
    ) throws -> [T] {
        var fetchRequest: FetchDescriptor<T> = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortDescriptors
        )

        // Handle pagination
        if case .paging(let offset, let limit) = fetchOptions {
            fetchRequest.fetchOffset = offset
            fetchRequest.fetchLimit = limit
        }

        // Handle property fetching
        if case .custom(let properties) = propertiesToFetch {
            fetchRequest.propertiesToFetch = properties
        }

        // Handle relationship prefetching
        if let relationshipKeyPathsForPrefetching {
            fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
        }

        return try modelContext.fetch(fetchRequest)
    }

    /// Fetches a single item by its persistent identifier.
    ///
    /// Use this method when you have an item's `PersistentIdentifier` and need to retrieve it.
    /// This is useful for passing references between views or storing bookmarks to items.
    ///
    /// - Parameter id: The persistent identifier of the item to fetch.
    ///
    /// - Returns: The model object if found, nil otherwise.
    ///
    /// - Example:
    ///   ```swift
    ///   if let todo = try todoStore.fetch(id: todoID) {
    ///       print("Found: \(todo.title)")
    ///   }
    ///   ```
    ///
    /// - SeeAlso: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-find-a-swiftdata-object-by-its-identifier
    public func fetch(id: PersistentIdentifier) throws -> T? {
        modelContext.registeredModel(for: id)
    }

    /// Fetches the count of items matching the given criteria.
    ///
    /// This method is more efficient than fetching all items when you only need the count.
    /// It's useful for displaying counts in UI or checking if items exist.
    ///
    /// - Parameter predicate: Optional predicate to filter items before counting.
    ///
    /// - Returns: The number of items matching the criteria.
    ///
    /// - Throws: An error if the count operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let completedCount = try todoStore.fetchCount(
    ///       predicate: #Predicate { $0.isCompleted == true }
    ///   )
    ///   print("Completed todos: \(completedCount)")
    ///   ```
    public func fetchCount(predicate: Predicate<T>? = nil) throws -> Int {
        let fetchRequest: FetchDescriptor<T> = FetchDescriptor<T>(
            predicate: predicate
        )
        return try modelContext.fetchCount(fetchRequest)
    }

    // MARK: - Public Methods - Update

    /// Updates an existing item with the provided changes.
    ///
    /// This method ensures the item is registered with the context,
    /// applies the updates, and saves the changes.
    ///
    /// - Parameters:
    ///   - item: The model object to update.
    ///   - updates: A closure that receives the item and applies changes to it.
    ///
    /// - Throws: An error if the save operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   try todoStore.update(todo) { item in
    ///       item.title = "Updated title"
    ///       item.isCompleted = true
    ///       item.priority = .high
    ///   }
    ///   ```
    ///
    /// - Note: The item is automatically inserted into the context if not already present.
    public func update(_ item: T, updates: (T) -> Void) throws {
        // Ensure the item is in the context
        modelContext.insert(item)

        // Apply the updates
        updates(item)

        // Save only if there are changes
        if modelContext.hasChanges {
            try modelContext.save()
        }
        // The didSave notification will handle updating the items array
    }

    // MARK: - Public Methods - Delete

    /// Deletes a single item from the store.
    ///
    /// The item is immediately removed from the context and the change is saved.
    ///
    /// - Parameter item: The model object to delete.
    ///
    /// - Throws: An error if the delete operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   try todoStore.delete(todoToRemove)
    ///   ```
    public func delete(_ item: T) throws {
        modelContext.delete(item)
        try modelContext.save()
        // The didSave notification will trigger auto-fetch
    }

    /// Deletes all items matching the given predicate.
    ///
    /// This method efficiently deletes multiple items in a single operation.
    /// If no predicate is provided, all items of type T are deleted.
    ///
    /// - Parameter predicate: Optional predicate to filter items to delete.
    ///                       If nil, all items are deleted.
    ///
    /// - Throws: An error if the delete operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   // Delete all completed todos
    ///   try todoStore.deleteAll(
    ///       where: #Predicate { $0.isCompleted == true }
    ///   )
    ///
    ///   // Delete all todos
    ///   try todoStore.deleteAll()
    ///   ```
    ///
    /// - Warning: Use with caution as this operation cannot be undone.
    public func deleteAll(where predicate: Predicate<T>? = nil) throws {
        try modelContext.delete(model: T.self, where: predicate)
        try modelContext.save()
        // The didSave notification will trigger auto-fetch
    }
}
