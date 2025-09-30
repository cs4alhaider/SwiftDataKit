import SwiftData
import SwiftUI
import SwiftDataKit

// MARK: - Environment Values Extension

extension EnvironmentValues {
    /// A DataRepositoryStore for Todo items with auto-fetch enabled
    /// Automatically updates when the ModelContext changes
    @Entry var todos: DataRepositoryStore<Todo> = .init()

    /// An ObservableDataRepositoryStore for Todo items with auto-fetch enabled
    /// Automatically updates when the ModelContext changes
    @Entry var observableTodos: ObservableDataRepositoryStore<Todo> = .init(
        fetchConfiguration: FetchConfigrations(
            sortDescriptors: TodoSortConfiguration.standard,
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions: .all
        )
    )
}
