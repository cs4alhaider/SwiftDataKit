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
@Observable
final class ObservableDataStore<T>: ObservableDataRepository where T: PersistentModel {

    // MARK: - Public Properties

    /// The current items in the store, automatically updated when the ModelContext changes
    public internal(set) var items: [T] = []

    // MARK: - Private Properties

    /// The model context used for all data operations.
    /// This context is obtained from the shared SwiftDataKit instance.
    private let modelContext: ModelContext

    /// Cancellables for Combine subscriptions
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    /// Current fetch configuration for auto-fetching
    private var currentFetchConfiguration: FetchConfiguration?

    // MARK: - Types

    /// Configuration for automatic fetching
    enum FetchConfiguration {
        case none
        case enabled(
            sortDescriptors: [SortDescriptor<T>] = [],
            predicate: Predicate<T>? = nil,
            propertiesToFetch: PropertiesOption<T> = .all,
            relationshipKeyPathsForPrefetching: [PartialKeyPath<T>]? = nil,
            fetchOptions: FetchOptions = .all
        )
    }

    // MARK: - Initialization

    /// Initializes a new DataStore instance.
    ///
    /// The store automatically uses the shared SwiftDataKit's model context,
    /// which must be configured before creating any DataStore instances.
    ///
    /// - Parameters:
    ///   - modelContext: Optional custom ModelContext. If nil, uses SwiftDataKit.shared.modelContext
    ///   - fetchConfiguration: Configuration for automatic fetching. Use .enabled to auto-fetch items
    ///
    /// - Note: Ensure `SwiftDataKit.configure()` has been called at app startup
    ///         before creating DataStore instances.
    init(modelContext: ModelContext? = nil, fetchConfiguration: FetchConfiguration = .none) {
        self.modelContext = modelContext ?? SwiftDataKit.shared.modelContext
        self.currentFetchConfiguration = fetchConfiguration

        // Setup notification listeners
        setupNotificationListeners()

        // Perform initial fetch if configuration is enabled
        if case .enabled(
            let sortDescriptors, let predicate, let propertiesToFetch,
            let relationshipKeyPathsForPrefetching, let fetchOptions) = fetchConfiguration
        {
            do {
                self.items = try fetch(
                    sortedBy: sortDescriptors,
                    predicate: predicate,
                    propertiesToFetch: propertiesToFetch,
                    relationshipKeyPathsForPrefetching: relationshipKeyPathsForPrefetching,
                    fetchOptions: fetchOptions
                )
            } catch {
                print("Error performing initial fetch: \(error)")
                self.items = []
            }
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

        // For enabled configuration, always re-fetch when any save occurs
        // This ensures we catch all updates, even when userInfo is incomplete
        if case .enabled = currentFetchConfiguration {
            // Check if this context has any registered objects of our type
            // If yes, perform auto-fetch to get the latest state
            performAutoFetch()
        } else if case .none? = currentFetchConfiguration {
            // For .none configuration, try to manually update based on notification
            if let userInfo = notification.userInfo {
                let inserted = (userInfo["inserted"] as? Set<PersistentIdentifier>) ?? []
                let deleted = (userInfo["deleted"] as? Set<PersistentIdentifier>) ?? []
                let updated = (userInfo["updated"] as? Set<PersistentIdentifier>) ?? []

                if !updated.isEmpty {
                    print(updated)
                }

                if !inserted.isEmpty || !deleted.isEmpty || !updated.isEmpty {
                    updateItemsFromNotification(notification)
                }
            }
        }
    }

    /// Updates items array based on notification changes (for .none configuration)
    private func updateItemsFromNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let inserted = (userInfo["inserted"] as? Set<PersistentIdentifier>) ?? []
        let deleted = (userInfo["deleted"] as? Set<PersistentIdentifier>) ?? []
        let updated = (userInfo["updated"] as? Set<PersistentIdentifier>) ?? []
        if !updated.isEmpty {
            print(updated)
        }
        // Remove deleted items
        if !deleted.isEmpty {
            items.removeAll { (item: T) in
                deleted.contains(item.persistentModelID)
            }
        }

        // Add inserted items
        for identifier in inserted {
            if let model: T = modelContext.registeredModel(for: identifier) {
                // Check if item already exists (to avoid duplicates)
                if !items.contains(where: { $0.persistentModelID == identifier }) {
                    items.append(model)
                }
            }
        }

        // Update existing items (they're already updated in memory due to SwiftData's behavior)
        // We just need to trigger the @Observable update
        if !updated.isEmpty {
            // Force a refresh by creating a new array
            items = items.map { $0 }
        }
    }

    /// Performs automatic fetch based on current configuration
    private func performAutoFetch() {
        guard
            case .enabled(
                let sortDescriptors, let predicate, let propertiesToFetch,
                let relationshipKeyPathsForPrefetching, let fetchOptions) =
                currentFetchConfiguration
        else {
            return
        }

        do {
            // Directly fetch from context to avoid recursion
            var fetchRequest: FetchDescriptor<T> = FetchDescriptor<T>(
                predicate: predicate,
                sortBy: sortDescriptors
            )

            if case .paging(let offset, let limit) = fetchOptions {
                fetchRequest.fetchOffset = offset
                fetchRequest.fetchLimit = limit
            }

            if case .custom(let properties) = propertiesToFetch {
                fetchRequest.propertiesToFetch = properties
            }

            if let relationshipKeyPathsForPrefetching {
                fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
            }

            // Fetch and update items
            let fetchedItems = try modelContext.fetch(fetchRequest)
            self.items = fetchedItems
        } catch {
            print("Error performing auto-fetch: \(error)")
        }
    }

    /// Updates the fetch configuration and refreshes items
    public func updateFetchConfiguration(_ configuration: FetchConfiguration) {
        self.currentFetchConfiguration = configuration

        if case .enabled = configuration {
            performAutoFetch()
        } else {
            // Clear items if switching to .none
            items = []
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
    func create(_ item: T) throws {
        modelContext.insert(item)
        try modelContext.save()

        // If fetchConfiguration is .none, manually add to items
        if case .none? = currentFetchConfiguration {
            items.append(item)
        }
        // If .enabled, the didSave notification will trigger auto-fetch
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
    func fetch(
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

        let fetchedItems = try modelContext.fetch(fetchRequest)

        // Update items array if fetchConfiguration is .none
        if case .none? = currentFetchConfiguration {
            self.items = fetchedItems
        }

        return fetchedItems
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
    func fetch(id: PersistentIdentifier) throws -> T? {
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
    func fetchCount(predicate: Predicate<T>? = nil) throws -> Int {
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
    func update(_ item: T, updates: (T) -> Void) throws {
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
    func delete(_ item: T) throws {
        modelContext.delete(item)
        try modelContext.save()

        // If fetchConfiguration is .none, manually remove from items
        if case .none? = currentFetchConfiguration {
            items.removeAll { $0.persistentModelID == item.persistentModelID }
        }
        // If .enabled, the didSave notification will trigger auto-fetch
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
    func deleteAll(where predicate: Predicate<T>? = nil) throws {
        try modelContext.delete(model: T.self, where: predicate)
        try modelContext.save()

        // If fetchConfiguration is .none, clear items or filter based on predicate
        if case .none? = currentFetchConfiguration {
            if predicate == nil {
                items = []
            } else {
                // Note: We can't evaluate the predicate directly on the items array
                // So we clear all items and rely on a manual fetch if needed
                items = []
            }
        }
        // If .enabled, the didSave notification will trigger auto-fetch
    }
}

// MARK: - Usage Examples

/// Example class demonstrating how to use the DataStore.
///
/// This class shows various common patterns and use cases for the DataStore.
/// These examples use the Todo model but apply to any PersistentModel type.
///
@MainActor
class ObservableDataStoreUsageExamples {

    // Create a store instance for Todo model with auto-fetch enabled
    let todoStore = ObservableDataStore<Todo>(
        fetchConfiguration: .enabled(
            sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions: .all
        )
    )

    // Create a store instance without auto-fetch
    let manualTodoStore = DataStore<Todo>()

    // MARK: - Fetching Examples

    /// Access auto-fetched todos
    var todos: [Todo] {
        todoStore.items
    }

    /// Fetch todos with only title property loaded (for performance)
    func fetchTodoTitles() throws -> [Todo] {
        try manualTodoStore.fetch(
            propertiesToFetch: .custom([\Todo.title])
        )
    }

    /// Get total count of todos
    func getTodosCount() throws -> Int {
        try todoStore.fetchCount()
    }

    /// Fetch high priority incomplete todos, sorted by date
    func fetchUrgentTodos() throws -> [Todo] {
        let high = Priority.high
        return try todoStore.fetch(
            sortedBy: [SortDescriptor(\.createdAt, order: .forward)],
            predicate: #Predicate { todo in
                todo.priority == high && !todo.isCompleted
            },
            fetchOptions: .paging(offset: 0, limit: 20)
        )
    }

    // MARK: - Create/Update/Delete Examples

    /// Create a new todo
    func createTodo(title: String, priority: Priority = .medium) throws {
        let todo = Todo(title: title, priority: priority)
        try todoStore.create(todo)
        // todoStore.items will automatically update
    }

    /// Update multiple properties of a todo
    func updateTodo(
        _ todo: Todo,
        newTitle: String? = nil,
        newPriority: Priority? = nil,
        toggleComplete: Bool = false
    ) throws {
        try todoStore.update(todo) { item in
            if let newTitle = newTitle {
                item.title = newTitle
            }
            if let newPriority = newPriority {
                item.priority = newPriority
            }
            if toggleComplete {
                item.isCompleted.toggle()
            }
        }
        // todoStore.items will automatically update
    }

    /// Delete a specific todo
    func deleteTodo(_ todo: Todo) throws {
        try todoStore.delete(todo)
        // todoStore.items will automatically update
    }

    /// Delete all completed todos
    func deleteCompletedTodos() throws {
        try todoStore.deleteAll(
            where: #Predicate { $0.isCompleted == true }
        )
        // todoStore.items will automatically update
    }

    /// Clear all todos
    func deleteAllTodos() throws {
        try todoStore.deleteAll()
        // todoStore.items will automatically update
    }
}
