# Dependency Injection System

## 📖 Overview

This document explains the dependency injection (DI) system used in the Pinterest Clone application. Understanding DI is crucial for writing maintainable, testable, and modular code.

---

## 🎯 What is Dependency Injection?

**Dependency Injection** is a design pattern where an object receives its dependencies from external sources rather than creating them itself.

### Without DI (Tight Coupling)
```swift
class PinViewModel {
    let repository = PinRepository() // ❌ Hard dependency
    
    func loadPins() {
        repository.fetchAll()
    }
}
```

**Problems:**
- Hard to test (can't mock repository)
- Tightly coupled to PinRepository
- Can't swap implementations
- Difficult to reuse

### With DI (Loose Coupling)
```swift
class PinViewModel {
    let repository: PinRepositoryProtocol // ✅ Depends on protocol
    
    init(repository: PinRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadPins() {
        repository.fetchAll()
    }
}
```

**Benefits:**
- Easy to test (inject mocks)
- Loosely coupled
- Can swap implementations
- Highly reusable

---

## 🏗️ Container Architecture

Our DI system uses a **Service Locator** pattern with a central `Container`:

```
┌─────────────────────────────────────────┐
│           DI Container                  │
├─────────────────────────────────────────┤
│  Registrations:                         │
│  - DatabaseManager (Singleton)          │
│  - PinRepository (Transient)            │
│  - BoardRepository (Transient)          │
│  - PinService (Singleton)               │
│  - ViewModels (Transient)               │
└─────────────────────────────────────────┘
         ▲              ▲              ▲
         │              │              │
    Register         Resolve        Inject
         │              │              │
    [App Init]    [Manual Code]  [@Injected]
```

---

## 📦 Service Lifecycles

### 1. Singleton
**One instance for entire app lifetime**

```swift
container.register(DatabaseManager.self, lifecycle: .singleton) { _ in
    DatabaseManager.shared
}
```

**Use for:**
- Database connections
- Network clients
- Configuration managers
- Cache managers

### 2. Transient
**New instance every time resolved**

```swift
container.register(PinRepository.self, lifecycle: .transient) { container in
    PinRepository(database: container.resolve())
}
```

**Use for:**
- Repositories
- View models
- Stateless services

### 3. Scoped
**One instance per scope (e.g., per request, per view)**

```swift
container.register(UserSession.self, lifecycle: .scoped) { _ in
    UserSession()
}
```

**Use for:**
- User sessions
- Request-specific data
- View-specific state

---

## 🔧 Registration Methods

### Method 1: Factory Function
```swift
container.register(PinServiceProtocol.self) { container in
    PinService(repository: container.resolve())
}
```

### Method 2: Direct Instance (Singleton)
```swift
container.registerSingleton(DatabaseManager.self, instance: DatabaseManager.shared)
```

### Method 3: Auto-Registration Protocol
```swift
class MyService: AutoRegistrable {
    static var lifecycle: ServiceLifecycle { .singleton }
    
    static func register(in container: Container) {
        container.register(MyService.self, lifecycle: lifecycle) { _ in
            MyService()
        }
    }
}
```

---

## 💉 Injection Methods

### 1. Property Wrapper (Recommended)
```swift
class PinViewModel: ObservableObject {
    @Injected var repository: PinRepositoryProtocol
    
    func loadPins() {
        repository.fetchAll()
    }
}
```

**Pros:**
- Clean syntax
- Automatic resolution
- Type-safe

**Cons:**
- Must have default initializer
- Harder to test without setup

### 2. Constructor Injection (Best for Testing)
```swift
class PinViewModel: ObservableObject {
    let repository: PinRepositoryProtocol
    
    init(repository: PinRepositoryProtocol = Container.shared.resolve()) {
        self.repository = repository
    }
}

// Testing:
let mockRepo = MockPinRepository()
let viewModel = PinViewModel(repository: mockRepo)
```

**Pros:**
- Explicit dependencies
- Easy to test
- Immutable dependencies

**Cons:**
- More verbose

### 3. Method Injection
```swift
class PinViewModel: ObservableObject {
    func configure(repository: PinRepositoryProtocol) {
        self.repository = repository
    }
}
```

**Pros:**
- Flexible
- Can inject after initialization

**Cons:**
- Easy to forget
- Mutable state

---

## 🗂️ Module System

Organize related services into **modules**:

```swift
struct DatabaseModule: DIModule {
    func registerServices(in container: Container) {
        container.registerSingleton(DatabaseManager.self, instance: .shared)
        container.register(PinRepository.self, lifecycle: .transient) { c in
            PinRepository(database: c.resolve())
        }
    }
}
```

**Benefits:**
- Organized registration
- Easy to enable/disable features
- Clear service boundaries

---

## 🧪 Testing with DI

### Setup Test Container
```swift
class PinViewModelTests: XCTestCase {
    var container: Container!
    var mockRepository: MockPinRepository!
    var viewModel: PinViewModel!
    
    override func setUp() {
        container = Container.test()
        mockRepository = MockPinRepository()
        
        // Register mock
        container.registerMock(PinRepositoryProtocol.self, mock: mockRepository)
        
        // Create view model with mock
        viewModel = container.resolve()
    }
    
    func testLoadPins() async {
        // Given
        mockRepository.pins = [Pin.sample]
        
        // When
        await viewModel.loadPins()
        
        // Then
        XCTAssertEqual(viewModel.pins.count, 1)
    }
}
```

### Mock Implementation
```swift
class MockPinRepository: PinRepositoryProtocol {
    var pins: [Pin] = []
    var fetchAllCalled = false
    
    func fetchAll() async throws -> [Pin] {
        fetchAllCalled = true
        return pins
    }
    
    func create(_ pin: Pin) async throws -> Pin {
        var newPin = pin
        newPin.id = Int64.random(in: 1...1000)
        pins.append(newPin)
        return newPin
    }
}
```

---

## 🎨 Best Practices

### 1. Program to Interfaces
```swift
// ✅ Good
protocol PinRepositoryProtocol { }
@Injected var repository: PinRepositoryProtocol

// ❌ Bad
@Injected var repository: PinRepository // Concrete type
```

### 2. Register at App Startup
```swift
@main
struct PinterestApp: App {
    init() {
        Container.registerAppModules()
    }
}
```

### 3. Use Meaningful Names
```swift
// ✅ Good
protocol PinServiceProtocol { }
protocol PinRepositoryProtocol { }

// ❌ Bad
protocol PinProtocol { } // Too vague
protocol IPinService { } // Hungarian notation
```

### 4. Keep Container Pure
```swift
// ✅ Good
container.register(MyService.self) { c in
    MyService(dep: c.resolve())
}

// ❌ Bad
container.register(MyService.self) { _ in
    let service = MyService()
    service.configure()      // Side effects
    NetworkManager.shared.setup()  // Global state
    return service
}
```

### 5. Prefer Constructor Injection for ViewModels
```swift
// ✅ Good - testable
class PinViewModel {
    init(service: PinServiceProtocol = Container.shared.resolve()) {
        self.service = service
    }
}

// ❌ Acceptable but harder to test
class PinViewModel {
    @Injected var service: PinServiceProtocol
}
```

---

## 🔍 Debugging

### Print Dependency Tree
```swift
Container.shared.printDependencyTree()

// Output:
// 📊 Dependency Container Status:
// ================================
// 🔒 DatabaseManager [✅]
// 🔄 PinRepository [⏳]
// 🔄 BoardRepository [⏳]
// 🔒 PinService [✅]
// ================================
// Total services: 4
```

### Check Registration
```swift
if Container.shared.isRegistered(PinService.self) {
    print("✅ PinService is registered")
}
```

### List All Services
```swift
let services = Container.shared.listServices()
print("Registered services: \(services)")
```

---

## ⚠️ Common Pitfalls

### 1. Circular Dependencies
```swift
// ❌ A depends on B, B depends on A
class ServiceA {
    @Injected var serviceB: ServiceB
}

class ServiceB {
    @Injected var serviceA: ServiceA
}
```

**Solution:** Use protocols and lazy initialization

### 2. Forgetting to Register
```swift
// ❌ Trying to resolve unregistered service
@Injected var service: MyService // Crash!
```

**Solution:** Always register before resolving

### 3. Wrong Lifecycle
```swift
// ❌ Using singleton for stateful view model
container.register(PinViewModel.self, lifecycle: .singleton)
```

**Solution:** Use transient for view models

---

## 🚀 Advanced Patterns

### Property Injection with Observation
```swift
@propertyWrapper
struct InjectedObserved<T: ObservableObject> {
    @StateObject private var object: T
    
    init() {
        _object = StateObject(wrappedValue: Container.shared.resolve())
    }
    
    var wrappedValue: T {
        object
    }
}

// Usage in SwiftUI
struct PinGridView: View {
    @InjectedObserved var viewModel: PinGridViewModel
}
```

### Keyed Registration
```swift
enum CacheType {
    case memory
    case disk
}

// Register multiple implementations
container.register("memory_cache", ImageCacheProtocol.self) { _ in
    MemoryImageCache()
}

container.register("disk_cache", ImageCacheProtocol.self) { _ in
    DiskImageCache()
}
```

### Factory Pattern
```swift
protocol ViewModelFactory {
    func makePinViewModel() -> PinViewModel
    func makeBoardViewModel() -> BoardViewModel
}

class DefaultViewModelFactory: ViewModelFactory {
    @Injected var container: Container
    
    func makePinViewModel() -> PinViewModel {
        container.resolve()
    }
}
```

---

## 📚 Further Reading

- [Dependency Injection Principles](https://en.wikipedia.org/wiki/Dependency_injection)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Service Locator Pattern](https://martinfowler.com/articles/injection.html)

---

## 💡 Summary

| Concept | Description | Use Case |
|---------|-------------|----------|
| **Singleton** | One instance app-wide | Database, Network |
| **Transient** | New instance each time | Repositories, VMs |
| **Scoped** | One per scope | User sessions |
| **@Injected** | Auto-inject property | Quick access |
| **Constructor** | Inject via init | Best for testing |
| **Protocol** | Interface-based | Abstraction |
| **Module** | Group registrations | Organization |

---

**Remember:** Good DI leads to testable, maintainable, and flexible code! 🎉

