import SwiftData
import SwiftUI

// MARK: - Environment Values Extension

extension EnvironmentValues {
    /// A DataStore for Todo items with auto-fetch enabled
    /// Automatically updates when the ModelContext changes
    @Entry var todos: DataStore<Todo> = .init()

    /// A DataStore for Todo items with auto-fetch enabled
    /// Automatically updates when the ModelContext changes
    @Entry var observableTodos: ObservableDataStore<Todo> = .init(
        fetchConfiguration: FetchConfigrations(
            sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions: .all
        )
    )
}
