# Views Structure

This folder contains three example implementations of the same Todo list app, each demonstrating a different data management approach.

## Folder Structure

```
Views/
├── SharedComponents/         # Reusable UI components
│   ├── TodoRow.swift         # Shared todo item row
│   ├── AddTodoView.swift     # Shared add form
│   └── EditTodoView.swift    # Shared edit form
│
├── NativeExample/            # Native SwiftUI approach (Auto-sync by default)
│   └── NativeTodoListView.swift
│
├── ObservableExample/        # Auto-syncing observable store
│   └── ObservableTodoListView.swift
│
├── ManualExample/            # Manual fetch control
│   └── TodoListView.swift
│
└── SettingsView.swift        # App settings/info
```

## Consistent UI Across All Examples

All three examples now share:

- ✅ Same `TodoRow` component (with animations)
- ✅ Identical section layout (Active/Completed with counts)
- ✅ Same transitions and animations
- ✅ Consistent toolbar (Total count badge)
- ✅ Shared Add/Edit forms
- ✅ Same sort order (newest first via `TodoSortConfiguration.standard`)

## The Three Approaches

### 1. Native Example (`@Query` + `ModelContext`)

```swift
@Query(sort: \Todo.createdAt, order: .reverse) private var todos: [Todo]
@Environment(\.modelContext) private var modelContext: ModelContext
```

**Best for:** Simple apps, learning SwiftData basics

### 2. Observable Example (`ObservableDataStore`)

```swift
@Environment(\.observableTodos) private var todosStore: ObservableDataStore<Todo>
// Auto-syncs across all screens via ModelContext.didSave notifications
```

**Best for:** Multi-screen apps needing real-time sync

### 3. Manual Example (`DataStore`)

```swift
@Environment(\.todos) private var todosStore: DataStore<Todo>
@State private var todos: [Todo] = []
// Explicit fetch() calls for full control
```

**Best for:** Performance-critical apps, custom fetch strategies

## Comparison

| Feature               | Native  | Observable | Manual   |
| --------------------- | ------- | ---------- | -------- |
| Shared Row Component  | ✅      | ✅         | ✅       |
| Auto-updates          | ✅      | ✅         | ❌       |
| Cross-screen sync     | ❌      | ✅         | ❌       |
| Full fetch control    | ❌      | ❌         | ✅       |
| Environment injection | ❌      | ✅         | ✅       |
| Code complexity       | Low     | Medium     | Medium   |
| Boilerplate           | Minimal | Minimal    | Moderate |
