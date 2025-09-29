//
//  SwiftDataKit.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 29/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

/// SwiftDataKit is a singleton manager for SwiftData's ModelContainer and ModelContext.
/// It provides a centralized way to configure and access the data store throughout the application.
///
/// ## Overview
/// This class follows the singleton pattern to ensure only one instance of the database
/// configuration exists throughout the app lifecycle. It manages both the ModelContainer
/// (which defines the schema and storage configuration) and the ModelContext
/// (which handles the actual data operations).
///
/// ## Usage Example
/// ```swift
/// // Configure at app startup
/// try SwiftDataKit.configure(
///     for: Todo.self, User.self,
///     config: ModelConfiguration(isStoredInMemoryOnly: false)
/// )
///
/// // Access anywhere in the app
/// let context = SwiftDataKit.shared.modelContext
/// let container = SwiftDataKit.shared.modelContainer
/// ```
///
/// ## Important Notes
/// - Must call `configure()` before accessing modelContainer or modelContext
/// - Configuration should happen once at app startup
/// - Thread-safe singleton implementation
/// - Supports migration plans for schema changes
///
@Observable
public class SwiftDataKit {

    // MARK: - Singleton Instance

    /// The shared singleton instance of SwiftDataKit.
    /// This ensures only one database configuration exists in the app.
    public static let shared: SwiftDataKit = SwiftDataKit()

    // MARK: - Public Properties

    /// The ModelContainer that manages the persistent store.
    /// This property will crash if accessed before calling `configure()`.
    ///
    /// The ModelContainer is responsible for:
    /// - Managing the underlying storage (SQLite database)
    /// - Defining the data model schema
    /// - Handling migrations between schema versions
    public var modelContainer: ModelContainer {
        guard let modelContainer: ModelContainer = _modelContainer else {
            fatalError("ModelContainer not initialized. Call SwiftDataKit.configure() at app startup before accessing the container.")
        }
        return modelContainer
    }

    /// The main ModelContext for data operations.
    /// This property will crash if accessed before calling `configure()`.
    ///
    /// The ModelContext is responsible for:
    /// - Fetching data from the store
    /// - Tracking changes to model objects
    /// - Saving changes back to the store
    /// - Managing the object graph
    public var modelContext: ModelContext {
        guard let modelContext: ModelContext = _modelContext else {
            fatalError("ModelContext not initialized. Call SwiftDataKit.configure() at app startup before accessing the context.")
        }
        return modelContext
    }

    // MARK: - Private Properties

    /// Internal storage for the ModelContainer.
    /// Kept private to ensure controlled access through the public computed property.
    private var _modelContainer: ModelContainer?

    /// Internal storage for the ModelContext.
    /// Kept private to ensure controlled access through the public computed property.
    private var _modelContext: ModelContext?

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern.
    /// This prevents external instantiation of the class.
    private init() {
        // Empty initializer - configuration happens via configure() method
    }

    // MARK: - Public Configuration Methods

    /// Configures the SwiftDataKit with the provided models and settings.
    ///
    /// This method should be called once at app startup, typically in the App's initializer.
    /// It sets up the entire data stack including the container and context.
    ///
    /// - Parameters:
    ///   - models: Variadic parameter of PersistentModel types to be managed by SwiftData.
    ///             Example: `Todo.self, User.self, Project.self`
    ///   - migrationPlan: Optional migration plan for handling schema changes between app versions.
    ///                    Pass nil if no migrations are needed.
    ///   - config: The ModelConfiguration that defines storage settings.
    ///             Defaults to persistent storage (not in-memory).
    ///
    /// - Throws: An error if the ModelContainer could not be created.
    ///           Common errors include:
    ///           - Invalid model schema
    ///           - Storage permission issues
    ///           - Migration failures
    ///
    /// - Example:
    ///   ```swift
    ///   do {
    ///       try SwiftDataKit.configure(
    ///           for: Todo.self, User.self,
    ///           migrationPlan: AppMigrationPlan.self,
    ///           config: ModelConfiguration(
    ///               isStoredInMemoryOnly: false,
    ///               allowsSave: true
    ///           )
    ///       )
    ///   } catch {
    ///       fatalError("Failed to configure database: \(error)")
    ///   }
    ///   ```
    public static func configure(
        for models: any PersistentModel.Type...,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        config: ModelConfiguration = .init(isStoredInMemoryOnly: false)
    ) throws {
        // Create schema from the provided models
        let schema = Schema(models)

        // Initialize the shared instance with the schema
        try shared.initialize(
            for: schema,
            migrationPlan: migrationPlan,
            config: config
        )
    }

    // MARK: - Private Helper Methods

    /// Internal initialization method that sets up the ModelContainer and ModelContext.
    ///
    /// This method performs the actual configuration of the data stack.
    /// It's kept private to ensure initialization only happens through the public `configure()` method.
    ///
    /// - Parameters:
    ///   - schema: The Schema object containing all model types
    ///   - migrationPlan: Optional migration plan for schema changes
    ///   - config: The ModelConfiguration for storage settings
    ///
    /// - Throws: An error if the ModelContainer creation fails
    ///
    /// - Note: This method enables autosave on the context for automatic persistence
    private func initialize(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        config: ModelConfiguration = .init(isStoredInMemoryOnly: false)
    ) throws {
        // Create the ModelContainer with the provided configuration
        let container: ModelContainer = try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: config
        )

        // Store the container
        self._modelContainer = container

        // Create a ModelContext from the container
        // This context will be used for all data operations
        self._modelContext = ModelContext(container)

        // Enable autosave to automatically persist changes
        // This means calling save() is not always necessary
        self._modelContext?.autosaveEnabled = true
    }

    // MARK: - Utility Methods

    /// Checks if the database has been configured.
    ///
    /// Useful for conditional logic or debugging to verify initialization status.
    ///
    /// - Returns: true if configure() has been called successfully, false otherwise
    public var isConfigured: Bool {
        return _modelContainer != nil && _modelContext != nil
    }

    /// Resets the database configuration.
    ///
    /// **Warning**: This method should only be used for testing or special scenarios.
    /// It will invalidate all existing references to the context and container.
    ///
    /// After calling this method, you must call `configure()` again before
    /// accessing the database.
    public func reset() {
        _modelContext = nil
        _modelContainer = nil
    }
}

// MARK: - SwiftDataKit Extensions

extension SwiftDataKit {

    /// Creates a new background ModelContext for concurrent operations.
    ///
    /// Use this when you need to perform data operations on a background queue
    /// without blocking the main thread.
    ///
    /// - Returns: A new ModelContext instance for background operations
    ///
    /// - Example:
    ///   ```swift
    ///   Task {
    ///       let backgroundContext = SwiftDataKit.shared.newBackgroundContext()
    ///       // Perform heavy data operations
    ///       try backgroundContext.save()
    ///   }
    ///   ```
    public func newBackgroundContext() -> ModelContext {
        return ModelContext(modelContainer)
    }
}
