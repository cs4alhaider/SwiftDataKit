//
//  Store.swift
//  LocationKit
//
//  Created by Abdullah Alhaider on 2024-11-21.
//

import Foundation
import SwiftData

// MARK: - StoreProtocol

// Good to know:
// https://developer.apple.com/documentation/swiftdata/persistentmodel
// How to optimize:
// https://www.hackingwithswift.com/quick-start/swiftdata/how-to-optimize-the-performance-of-your-swiftdata-apps

/// A protocol defining the required functionality for a store system.
protocol StoreProtocol: Sendable {

    /// The type of the item to be stored.
    associatedtype Model: PersistentModel
      
    /// Saves an item to the storage.
    ///
    /// - Parameter item: The `Model` object representing the item to be saved.
    /// - Throws: An error if the item could not be saved.
    func save(_ item: Model) async throws
    
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
        sortedBy sortDescriptors: [SortDescriptor<Model>],
        predicate: Predicate<Model>?,
        propertiesToFetch: PropertiesOption<Model>,
        relationshipKeyPathsForPrefetching: [PartialKeyPath<Model>]?,
        fetchOptions: FetchOptions
    ) async throws -> [Model]

    /// Fetches a single item from the storage by its ID.
    ///
    /// - Parameter id: The ID of the item to fetch.
    /// - Returns: The `Model` object representing the fetched item, or `nil` if no item is found.
    /// - Throws: An error if the item could not be fetched.
    func fetch(id: PersistentIdentifier) async throws -> Model?
    
    /// Fetches the count of stored items.
    ///
    /// - Parameter predicate: An optional `Predicate<Model>` to filter the items.
    /// - Returns: The count of stored items.
    /// - Throws: An error if the count could not be fetched.
    func fetchCount(predicate: Predicate<Model>?) async throws -> Int
    
    /// Updates an existing item in the storage.
    ///
    /// - Parameters:
    ///   - item: The `Model` object to be updated.
    ///   - updates: A closure that performs the updates on the item.
    /// - Throws: An error if the item could not be updated.
    func update(_ item: Model, updates: (Model) -> Void) async throws

    /// Deletes a single item from the storage.
    ///
    /// - Parameter item: The `Model` object representing the item to be deleted.
    /// - Throws: An error if the item could not be deleted.
    func delete(_ item: Model) async throws

    /// Deletes all stored items.
    ///
    /// Discussion:
    /// - This method is used to delete all items that match the predicate.
    /// - If no predicate is provided, all items will be deleted and the model will be deleted from the store.
    /// - You can read more about it here: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-delete-a-swiftdata-object
    /// - Throws: An error if the items could not be deleted.
    func deleteAll(where predicate: Predicate<Model>?) async throws
}
