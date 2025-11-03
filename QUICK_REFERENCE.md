# Quick Reference Guide

## 🚀 Quick Start

```bash
# 1. Add GRDB package in Xcode
# 2. Build project (⌘B)
# 3. Run (⌘R)
```

---

## 📚 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                    │
│              (PinGridView, BoardView)               │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                   View Models                       │
│         (PinGridViewModel, BoardViewModel)          │
│              [@Injected dependencies]               │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                    Services                         │
│         (PinService, BoardService, etc.)            │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Repositories                       │
│     (PinRepository, BoardRepository, etc.)          │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              DatabaseManager (GRDB)                 │
│           [SQLite + Type-safe queries]              │
└─────────────────────────────────────────────────────┘
```

---

## 🗂️ File Organization

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `Database/` | GRDB setup | `DatabaseManager.swift` |
| `Models/Database/` | Data models | `User.swift`, `Pin.swift`, `Board.swift` |
| `Repositories/` | Data access | `PinRepository.swift` |
| `Services/` | Business logic | `PinService.swift` |
| `Modules/*/Views/` | UI components | `PinGridView.swift` |
| `Modules/*/ViewModels/` | MVVM logic | `PinGridViewModel.swift` |
| `Core/DI/` | Dependency injection | `Container.swift` |
| `Core/Plugins/` | Plugin system | `PluginManager.swift` |
| `Core/Runtime/` | Runtime utilities | `RuntimeInspector.swift` |
| `docs/` | Documentation | `*.md` files |

---

## 🔧 Common Tasks

### Add a New Model

1. Create model file in `Models/Database/`:
```swift
struct MyModel: Codable, Identifiable {
    var id: Int64?
    var name: String
}

extension MyModel: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "my_models"
}
```

2. Add migration in `DatabaseManager.swift`:
```swift
migrator.registerMigration("add_my_model") { db in
    try db.create(table: "my_models") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("name", .text).notNull()
    }
}
```

### Add a New Repository

```swift
protocol MyRepositoryProtocol {
    func fetchAll() async throws -> [MyModel]
}

class MyRepository: MyRepositoryProtocol {
    private let database: DatabaseManager
    
    init(database: DatabaseManager = .shared) {
        self.database = database
    }
    
    func fetchAll() async throws -> [MyModel] {
        try await database.read { db in
            try MyModel.fetchAll(db)
        }
    }
}
```

### Register in DI Container

```swift
// In DIModules.swift
container.register(MyRepositoryProtocol.self, lifecycle: .transient) { c in
    MyRepository(database: c.resolve())
}
```

### Create a New View Module

1. Create directory: `Modules/MyModule/`
2. Add ViewModel:
```swift
@MainActor
class MyViewModel: ObservableObject {
    @Injected var repository: MyRepositoryProtocol
    @Published var items: [MyModel] = []
    
    func load() async {
        items = try await repository.fetchAll()
    }
}
```

3. Add View:
```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.load() }
    }
}
```

### Create a Plugin

```swift
class MyPlugin: PinterestPlugin {
    var identifier: String { "com.my.plugin" }
    
    var metadata: PluginMetadata {
        PluginMetadata(
            identifier: identifier,
            name: "My Plugin",
            version: "1.0.0",
            author: "Me",
            description: "Does something cool",
            capabilities: .imageProcessing
        )
    }
    
    func initialize(context: PluginContext) async throws {
        // Setup
    }
    
    func execute(action: PluginAction) async throws -> PluginResult {
        // Your logic
        return .success(data: nil)
    }
}
```

---

## 🎯 Key Patterns

### Repository Pattern
```swift
Protocol → Implementation → DI Registration → Usage
```

### MVVM Pattern
```swift
Model → Repository → Service → ViewModel → View
```

### Plugin Pattern
```swift
Protocol → Implementation → Registration → Execution
```

### DI Pattern
```swift
Register → Resolve → Inject → Use
```

---

## 💉 Dependency Injection Cheat Sheet

### Registration

```swift
// Singleton
container.register(MyService.self, lifecycle: .singleton) { c in
    MyService()
}

// Transient (new instance each time)
container.register(MyService.self, lifecycle: .transient) { c in
    MyService(dependency: c.resolve())
}

// Direct instance
container.registerSingleton(MyService.self, instance: MyService.shared)
```

### Resolution

```swift
// Property wrapper
@Injected var service: MyService

// Manual resolve
let service: MyService = Container.shared.resolve()

// Constructor injection (preferred)
init(service: MyServiceProtocol = Container.shared.resolve()) {
    self.service = service
}
```

---

## 📊 GRDB Cheat Sheet

### Basic Queries

```swift
// Fetch all
let pins = try Pin.fetchAll(db)

// Fetch one
let pin = try Pin.fetchOne(db, key: 1)

// Filter
let pins = try Pin.filter(Column("title") == "Design").fetchAll(db)

// Order
let pins = try Pin.order(Column("createdAt").desc).fetchAll(db)

// Limit
let pins = try Pin.limit(10).fetchAll(db)
```

### Associations

```swift
// Define association
static let board = belongsTo(Board.self)

// Use association
let board = try pin.board.fetchOne(db)

// Including associated records
let pins = try Pin.including(required: Pin.board).fetchAll(db)
```

### Observations

```swift
let observation = ValueObservation.tracking { db in
    try Pin.fetchAll(db)
}

observation.start(in: dbQueue) { pins in
    print("Pins changed: \(pins.count)")
}
```

---

## 🧪 Testing Patterns

### Mock Repository

```swift
class MockPinRepository: PinRepositoryProtocol {
    var pins: [Pin] = []
    
    func fetchAll() async throws -> [Pin] {
        return pins
    }
}
```

### Test Setup

```swift
class MyTests: XCTestCase {
    var container: Container!
    var mockRepo: MockPinRepository!
    
    override func setUp() {
        container = Container.test()
        mockRepo = MockPinRepository()
        container.registerMock(PinRepositoryProtocol.self, mock: mockRepo)
    }
}
```

---

## 🐛 Debug Commands

### Console Commands

```swift
// Database stats
Task { try? await DatabaseManager.shared.getStats() }

// Performance report
PerformanceMonitor.shared.printStatistics()

// DI container info
Container.shared.printDependencyTree()

// Plugin list
PluginManager.shared.enabledPluginsList()
```

### Menu Commands (⌘ key shortcuts)

- **Learning Guide** - Opens documentation
- **Database Statistics** - Shows DB info (Debug)
- **Performance Report** - Shows metrics (Debug)
- **Clear Database** - Resets data (Debug)

---

## 📖 Learning Resources

| Topic | File | Link |
|-------|------|------|
| Overview | README.md | [View](../README.md) |
| Complete Guide | LEARNING_GUIDE.md | [View](../LEARNING_GUIDE.md) |
| Setup | SETUP.md | [View](../SETUP.md) |
| DI System | docs/DependencyInjection.md | [View](../docs/DependencyInjection.md) |

---

## 🎨 Color Palette

```swift
// App Colors
Color.accentColor         // Primary accent
Color.primary            // Text primary
Color.secondary          // Text secondary
Color(NSColor.controlBackgroundColor)  // Background
Color(NSColor.windowBackgroundColor)   // Window bg
```

---

## 🔑 Key Concepts

| Concept | Definition | Example |
|---------|------------|---------|
| **GRDB** | SQLite toolkit | `try Pin.fetchAll(db)` |
| **Repository** | Data access layer | `PinRepository.fetchAll()` |
| **Service** | Business logic | `PinService.createPin()` |
| **ViewModel** | View state manager | `PinGridViewModel` |
| **DI** | Dependency injection | `@Injected var service` |
| **Plugin** | Runtime extension | `PluginManager.execute()` |
| **Mirror** | Runtime reflection | `Mirror(reflecting: pin)` |

---

## ⚡ Performance Tips

1. **Use async/await** for database operations
2. **Batch database writes** when possible
3. **Use `.limit()` on large queries**
4. **Implement pagination** for lists
5. **Cache frequently accessed data**
6. **Monitor with** `PerformanceMonitor`
7. **Profile with Instruments**

---

## 🚨 Common Pitfalls

| Problem | Solution |
|---------|----------|
| Forgot to register service | Check `DIModules.swift` |
| Database not initialized | Run app once to create |
| Circular dependencies | Use protocols |
| Memory leaks | Use `weak` or `unowned` |
| Main thread blocking | Use `async/await` |
| Plugin not found | Check registration |

---

## 📝 Code Snippets

### Fetch with Error Handling

```swift
do {
    let pins = try await repository.fetchAll()
    print("✅ Loaded \(pins.count) pins")
} catch {
    print("❌ Error: \(error.localizedDescription)")
}
```

### Observe Database Changes

```swift
for await pins in repository.observe() {
    await MainActor.run {
        self.pins = pins
    }
}
```

### Measure Performance

```swift
let result = await PerformanceMonitor.shared.measure(name: "load_pins") {
    try await repository.fetchAll()
}
```

---

## 🎯 Next Steps

1. ✅ Read this guide
2. 📖 Follow [LEARNING_GUIDE.md](../LEARNING_GUIDE.md)
3. 💻 Code along with examples
4. 🧪 Write your own tests
5. 🚀 Build new features!

---

**Keep this guide handy!** Bookmark it for quick reference while coding.

[⬆ Back to Top](#quick-reference-guide)

