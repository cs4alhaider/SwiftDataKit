//
//  DataStore.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import Foundation
import SwiftData

// MARK: - DataStore Implementation

/// A generic data store for managing persistent model objects using SwiftData.
///
/// `DataStore` provides a type-safe interface for CRUD operations on any `PersistentModel` type.
/// It uses the shared `SwiftDataDB` instance to access the underlying model context.
///
/// ## Overview
/// This class implements the `StoreProtocol` and provides methods for:
/// - Saving new items
/// - Fetching items with sorting, filtering, and pagination
/// - Updating existing items
/// - Deleting individual items or batches
///
/// ## Usage Example
/// ```swift
/// let todoStore = DataStore<Todo>()
///
/// // Save a new todo
/// let todo = Todo(title: "Buy groceries")
/// try todoStore.save(todo)
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
/// For background operations, use `SwiftDataDB.shared.newBackgroundContext()`.
///
@MainActor
final class DataStore<T>: StoreProtocol where T: PersistentModel {

    // MARK: - Properties

    /// The model context used for all data operations.
    /// This context is obtained from the shared SwiftDataDB instance.
    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initializes a new DataStore instance.
    ///
    /// The store automatically uses the shared SwiftDataDB's model context,
    /// which must be configured before creating any DataStore instances.
    ///
    /// - Note: Ensure `SwiftDataDB.configure()` has been called at app startup
    ///         before creating DataStore instances.
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? SwiftDataDB.shared.modelContext
    }

    // MARK: - Public Methods - Create

    /// Saves a new item to the persistent store.
    ///
    /// This method inserts the item into the model context and immediately saves it.
    /// If autosave is enabled on the context, the save happens automatically.
    ///
    /// - Parameter item: The model object to be saved.
    ///
    /// - Throws: `DataStoreError.saveFailed` if the save operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   let newTodo = Todo(title: "Write documentation")
    ///   try todoStore.save(newTodo)
    ///   ```
    func save(_ item: T) throws {
        modelContext.insert(item)
        try modelContext.save()
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
        // ignoring `.all` as it's by default will fetch all items if not specified,
        if case .paging(let offset, let limit) = fetchOptions {
            fetchRequest.fetchOffset = offset
            fetchRequest.fetchLimit = limit
        }
        // Ignoring `.all` as it's by default will fetch all properties if not specified,
        if case .custom(let properties) = propertiesToFetch {
            fetchRequest.propertiesToFetch = properties
        }
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
    /// - Throws: `DataStoreError.saveFailed` if the save operation fails.
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
    }

    // MARK: - Public Methods - Delete

    /// Deletes a single item from the store.
    ///
    /// The item is immediately removed from the context and the change is saved.
    ///
    /// - Parameter item: The model object to delete.
    ///
    /// - Throws: `DataStoreError.saveFailed` if the delete operation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   try todoStore.delete(todoToRemove)
    ///   ```
    func delete(_ item: T) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    /// Deletes all items matching the given predicate.
    ///
    /// This method efficiently deletes multiple items in a single operation.
    /// If no predicate is provided, all items of type T are deleted.
    ///
    /// - Parameter predicate: Optional predicate to filter items to delete.
    ///                       If nil, all items are deleted.
    ///
    /// - Throws: `DataStoreError.saveFailed` if the delete operation fails.
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
    }
}

// MARK: - Usage Examples

/// Example class demonstrating how to use the DataStore.
///
/// This class shows various common patterns and use cases for the DataStore.
/// These examples use the Todo model but apply to any PersistentModel type.
///
@MainActor
class DataStoreUsageExamples {

    // Create a store instance for Todo model
    let todoStore = DataStore<Todo>()

    // MARK: - Fetching Examples

    /// Fetch todos with only title property loaded (for performance)
    func fetchTodoTitles() throws -> [Todo] {
        try todoStore.fetch(
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

    /// Save a new todo
    func createTodo(title: String, priority: Priority = .medium) throws {
        let todo = Todo(title: title, priority: priority)
        try todoStore.save(todo)
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
    }

    /// Delete a specific todo
    func deleteTodo(_ todo: Todo) throws {
        try todoStore.delete(todo)
    }

    /// Delete all completed todos
    func deleteCompletedTodos() throws {
        try todoStore.deleteAll(
            where: #Predicate { $0.isCompleted == true }
        )
    }

    /// Clear all todos
    func deleteAllTodos() throws {
        try todoStore.deleteAll()
    }
}
