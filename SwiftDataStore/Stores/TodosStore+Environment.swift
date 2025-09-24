import SwiftUI

// MARK: - Environment Values Extension

extension EnvironmentValues {
    @Entry var todos: DataStore<Todo> = .init()
}
