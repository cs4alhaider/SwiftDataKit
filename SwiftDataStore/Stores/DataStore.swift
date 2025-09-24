import SwiftData
import SwiftUI
import Foundation

// MARK: - DataStore Implementation

/// A class responsible for managing the storage of item data.
/// This class conforms to the `StoreProtocol` protocol and provides an implementation for saving, fetching,
/// and deleting item data using SwiftData.
@MainActor
final class DataStore<T>: StoreProtocol where T: PersistentModel {

    private let storeURL: URL
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    /// Initializes a new instance of `Store`.
    /// Attempts to create a `ModelContainer` for storing `Model` objects.
    init() {
        do {
            // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-change-swiftdatas-underlying-storage-filename
            storeURL = URL.documentsDirectory.appending(path: "DataStore.sqlite")
            // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-add-multiple-configurations-to-a-modelcontainer
            let config: ModelConfiguration = ModelConfiguration(url: storeURL)
            // BUG. FIXME, ModelContainer should take more than one Model
            let container: ModelContainer = try ModelContainer(
                for: T.self,
                configurations: config
            )
            self.modelContainer = container
            self.modelContext = ModelContext(container)
            self.modelContext.autosaveEnabled = false

        } catch {
            fatalError("Failed to create ModelContainer for \(T.self): \(error)")
        }
    }

    /// Saves an item to the storage.
    ///
    /// - Parameter item: The `Model` object representing the item to be saved.
    /// - Throws: An error if the item could not be saved.
    func save(_ item: T) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    /// Fetches all stored items.
    ///
    /// Parameters:
    /// - sortDescriptors: An array of `SortDescriptor<Model>` defining the sorting criteria.
    /// - predicate: An optional `Predicate<Model>` to filter the items.
    /// - propertiesToFetch: An array of `PartialKeyPath<Model>` defining the properties to fetch, defaults to fetching all properties.
    /// - relationshipKeyPathsForPrefetching: An array of `PartialKeyPath<Model>` relationship properties you want to prefetch.
    ///   This is empty by default because SwiftData doesn’t fetch relationships until they are used, but if you know you’ll use
    ///   that data then prefetching allows SwiftData to batch request it all for more efficiently.
    ///   check this for more info: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-custom-fetchdescriptor
    ///   and this: https://developer.apple.com/documentation/swiftdata/fetchdescriptor/relationshipkeypathsforprefetching
    ///
    /// - Returns: An array of `Model` objects representing the stored items.
    ///
    /// - Throws: An error if the items could not be fetched.
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
    
    /// Fetches a single item from the storage by its ID.
    ///
    /// - Parameter id: The ID of the item to fetch.
    /// - Returns: The `Model` object representing the fetched item, or `nil` if no item is found.
    /// - Throws: An error if the item could not be fetched.
    func fetch(id: PersistentIdentifier) throws -> T? {
        // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-find-a-swiftdata-object-by-its-identifier
        modelContext.registeredModel(for: id)
    }
    
    /// Fetches the count of stored items.
    ///
    /// - Parameter predicate: An optional `Predicate<Model>` to filter the items.
    /// - Returns: The count of stored items.
    /// - Throws: An error if the count could not be fetched.
    func fetchCount(predicate: Predicate<T>? = nil) throws -> Int {
        let fetchRequest: FetchDescriptor<T> = FetchDescriptor<T>(
            predicate: predicate
        )
        return try modelContext.fetchCount(fetchRequest)
    }
    
    /// Updates an existing item in the storage.
    ///
    /// - Parameters:
    ///   - item: The `Model` object to be updated.
    ///   - updates: A closure that performs the updates on the item.
    /// - Throws: An error if the item could not be updated.
    func update(_ item: T, updates: (T) -> Void) throws {
        updates(item)
        try modelContext.save()
    }

    func delete(_ item: T) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    /// Deletes all stored items.
    ///
    /// - Throws: An error if the items could not be deleted.
    func deleteAll(where predicate: Predicate<T>? = nil) throws {
        try modelContext.delete(model: T.self, where: predicate)
        try modelContext.save()
    }
}


@MainActor
class HowToUse {

    let todoStore = DataStore<Todo>()
    // ... and all the other models

    func todos() throws -> [Todo] {
        try todoStore.fetch(propertiesToFetch: .custom([\Todo.title]))
    }

    func todosCount() throws -> Int {
        try todoStore.fetchCount()
    }

    func deleteAllTodos() throws {
        try todoStore.deleteAll()
    }

    func todosNames() throws -> [Todo] {
        let todos = try todoStore.fetch(propertiesToFetch: .custom([\Todo.title]))
        return todos
    }

    func saveTodo(_ todo: Todo) throws {
        try todoStore.save(todo)
    }

    func updateTodo(_ todo: Todo, newTitle: String? = nil, newPriority: Priority? = nil, toggleComplete: Bool = false) throws {
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

    func deleteTodo(_ todo: Todo) throws {
        try todoStore.delete(todo)
    }
}
