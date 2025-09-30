//
//  ObservableStoreProtocol.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation

/// A protocol that combines `StoreProtocol` and `Observable` to provide observable data store functionality.
///
/// Types conforming to `ObservableStoreProtocol` must provide an observable array of items,
/// which can be used to automatically update UI or other observers when the data changes.
///
/// - Note: The `items` property should be kept in sync with the underlying data store.
///
protocol ObservableStoreProtocol: StoreProtocol, Observable {
    /// The current items in the store, which should be kept up-to-date and observable.
    var items: [Model] { get set }
}
