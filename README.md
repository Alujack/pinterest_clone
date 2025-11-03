# Pinterest Clone - Advanced Swift Learning Project

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**A comprehensive learning project demonstrating advanced Swift and macOS development concepts**

[Learning Guide](LEARNING_GUIDE.md) • [Documentation](docs/) • [Examples](Examples/)

</div>

---

## 🎯 Project Overview

This Pinterest Clone is not just another clone app—it's a **comprehensive learning platform** designed to teach you advanced Swift development concepts through hands-on implementation. Each feature is carefully crafted to demonstrate best practices and modern architectural patterns.

### What You'll Learn

✅ **Database Design** - Normalized schemas, relationships, migrations  
✅ **GRDB Persistence** - Type-safe SQLite access, observations, associations  
✅ **Custom Macros** - Swift 5.9+ macro system, code generation  
✅ **Dependency Injection** - IoC containers, lifecycle management  
✅ **Modular Architecture** - MVVM, feature modules, clean code  
✅ **Plugin System** - Runtime extensibility, dynamic loading  
✅ **Runtime Behaviour** - Reflection, introspection, performance monitoring  
✅ **Client-Server** - XPC services, background processing, IPC

---

## 📁 Project Structure

```
pinterest_clone/
├── 📱 pinterest_clone/              # Main application
│   ├── 🗄️ Database/                 # GRDB setup & migrations
│   │   └── DatabaseManager.swift
│   ├── 📊 Models/                   # Data models
│   │   └── Database/                # GRDB records (User, Pin, Board, Comment)
│   ├── 🏪 Repositories/             # Data access layer
│   │   ├── PinRepository.swift
│   │   └── BoardRepository.swift
│   ├── ⚙️ Services/                 # Business logic
│   │   ├── PinService.swift
│   │   └── BoardService.swift
│   ├── 🎨 Modules/                  # Feature modules (MVVM)
│   │   ├── PinModule/
│   │   │   ├── Views/
│   │   │   │   └── PinGridView.swift
│   │   │   └── ViewModels/
│   │   │       └── PinGridViewModel.swift
│   │   └── BoardModule/
│   ├── 🧩 UI/                       # Shared UI components
│   │   └── Components/
│   │       └── PinCard.swift
│   ├── 🔧 Core/                     # Core functionality
│   │   ├── DI/                      # Dependency injection
│   │   │   ├── Container.swift
│   │   │   └── DIModules.swift
│   │   ├── Plugins/                 # Plugin system
│   │   │   ├── PluginProtocol.swift
│   │   │   └── PluginManager.swift
│   │   └── Runtime/                 # Runtime utilities
│   │       └── RuntimeInspector.swift
│   └── 🔌 Plugins/                  # Built-in plugins
│       ├── VintageFilterPlugin.swift
│       └── BuiltInPlugins.swift
├── 📖 docs/                         # Documentation
│   ├── DependencyInjection.md
│   ├── DatabaseSchema.md
│   ├── PluginDevelopment.md
│   └── XPCCommunication.md
├── 💡 Examples/                     # Code examples
├── 📝 LEARNING_GUIDE.md            # Main learning guide
└── 📦 Package.swift                # Dependencies
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** (for Swift 5.9 features)
- **macOS 14.0+** (Sonoma or later)
- Basic Swift knowledge

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/pinterest-clone.git
   cd pinterest-clone
   ```

2. **Open in Xcode**

   ```bash
   open pinterest_clone.xcodeproj
   ```

3. **Build and Run** (⌘R)
   - The app will automatically:
     - Initialize the database
     - Seed sample data
     - Register plugins
     - Run demo examples in console

### First Run

On first launch, the app will:

1. Create a SQLite database at `~/Library/Application Support/PinterestClone/`
2. Run migrations to create tables
3. Insert sample data (users, boards, pins)
4. Display runtime examples in the Xcode console

---

## 📚 Learning Path

### Week 1: Foundation (Database & Persistence)

- [ ] Read [Database Design](LEARNING_GUIDE.md#1-database-design) section
- [ ] Explore `Models/Database/` files
- [ ] Study `DatabaseManager.swift`
- [ ] Understand GRDB associations
- [ ] Experiment with queries in `PinRepository.swift`

**Exercises:**

- Add a new model (e.g., `Tag`)
- Create a migration
- Implement a repository

### Week 2: Dependency Injection

- [ ] Read [DI Documentation](docs/DependencyInjection.md)
- [ ] Study `Core/DI/Container.swift`
- [ ] Understand service lifecycles
- [ ] Practice with `@Injected` property wrapper
- [ ] Create custom DI modules

**Exercises:**

- Register a new service
- Create a mock for testing
- Implement a new module

### Week 3: Modular Architecture

- [ ] Study `Modules/PinModule/`
- [ ] Understand MVVM pattern
- [ ] Learn view composition
- [ ] Explore `PinGridViewModel.swift`
- [ ] Practice with `@Published` and Combine

**Exercises:**

- Create a new module (e.g., UserModule)
- Implement a view model
- Add unit tests

### Week 4: Plugin System

- [ ] Read [Plugin Development](LEARNING_GUIDE.md#6-plugin-architecture)
- [ ] Study `Core/Plugins/PluginProtocol.swift`
- [ ] Explore example plugins
- [ ] Understand plugin lifecycle
- [ ] Create custom plugin

**Exercises:**

- Implement a new filter plugin
- Add export format
- Create plugin UI

### Week 5: Runtime & Performance

- [ ] Study `Core/Runtime/RuntimeInspector.swift`
- [ ] Learn Swift reflection (Mirror API)
- [ ] Explore performance monitoring
- [ ] Understand feature flags
- [ ] Practice with KeyPath

**Exercises:**

- Create custom runtime inspector
- Add performance metrics
- Implement feature toggle

### Week 6: Advanced Topics

- [ ] Study macro system (when implemented)
- [ ] Explore XPC services (when implemented)
- [ ] Learn about helper processes
- [ ] Understand IPC patterns

---

## 🎓 Key Concepts

### 1. Database Design with GRDB

**Entity-Relationship Model:**

```
User 1──<many Boards many>──1 Board 1──<many Pins many>──1 Pin
                                                              │
                                                              │
                                                         many │
                                                              ▼
                                                          Comment
```

**Key Files:**

- `Models/Database/User.swift` - User model with GRDB conformance
- `Models/Database/Board.swift` - Board with associations
- `Models/Database/Pin.swift` - Pin with computed properties
- `Database/DatabaseManager.swift` - Migrations and setup

**Example Usage:**

```swift
// Fetch pins with board info
let pins = try await repository.fetchAll()

// Search with full-text search
let results = try await repository.search(query: "design")

// Observe changes
for await pins in repository.observe() {
    print("Pins updated: \(pins.count)")
}
```

### 2. Dependency Injection Container

**Service Registration:**

```swift
// In app initialization
Container.registerAppModules()

// Services are organized into modules
DatabaseModule()    // Database & repositories
ServiceModule()     // Business logic services
ViewModelModule()   // View models
```

**Usage Patterns:**

```swift
// Property wrapper injection
class ViewModel {
    @Injected var service: PinServiceProtocol
}

// Constructor injection (preferred for testing)
class ViewModel {
    init(service: PinServiceProtocol = Container.shared.resolve()) {
        self.service = service
    }
}
```

### 3. Plugin Architecture

**Plugin Capabilities:**

- 🎨 Image Processing (filters, adjustments)
- 📤 Export (JSON, PDF, HTML, CSV)
- 🔗 Sharing (social media integration)
- 🎨 UI Customization (themes, widgets)
- 📊 Analytics (image analysis, metrics)

**Example Plugin:**

```swift
class CustomFilterPlugin: PinterestPlugin {
    func execute(action: PluginAction) async throws -> PluginResult {
        // Your plugin logic
    }
}

// Register and use
await PluginManager.shared.register(plugin: CustomFilterPlugin())
await PluginManager.shared.enable(identifier: "com.custom.filter")
let result = try await PluginManager.shared.execute(
    identifier: "com.custom.filter",
    action: .imageFilter(imageData, filterName: "custom")
)
```

### 4. Runtime Introspection

**Reflection Examples:**

```swift
// Inspect any object
RuntimeInspector.inspect(pin)

// Get property names
let properties = RuntimeInspector.propertyNames(of: pin)

// Convert to dictionary
let dict = RuntimeInspector.toDictionary(pin)
```

**Performance Monitoring:**

```swift
// Measure execution time
let result = PerformanceMonitor.shared.measure(name: "fetch_pins") {
    try await repository.fetchAll()
}

// View statistics
PerformanceMonitor.shared.printStatistics()
```

---

## 🧪 Testing

### Unit Tests

```swift
class PinServiceTests: XCTestCase {
    var service: PinService!
    var mockRepository: MockPinRepository!

    override func setUp() {
        mockRepository = MockPinRepository()
        service = PinService(repository: mockRepository)
    }

    func testCreatePin() async throws {
        let pin = Pin.samples.first!
        let created = try await service.createPin(pin)
        XCTAssertNotNil(created.id)
    }
}
```

### Running Tests

```bash
# Run all tests
⌘U in Xcode

# Run specific test
⌃⌥⌘U on test method
```

---

## 🔧 Development Tools

### Xcode Menu Commands

**Help Menu:**

- **Learning Guide** - Opens LEARNING_GUIDE.md
- **Plugin Manager** - Manage plugins

**Debug Menu (Development Only):**

- **Database Statistics** - View DB stats
- **Performance Report** - Print metrics
- **Clear Database** - Reset and re-seed

### Console Output

The app provides rich console output:

```
🚀 Pinterest Clone Starting...
📦 Registered: DatabaseManager [singleton]
📦 Registered: PinRepository [transient]
✅ DatabaseModule registered
✅ ServiceModule registered
✅ ViewModelModule registered
✅ Built-in plugins registered
✅ Loaded 4 pins
```

---

## 🎨 Features

### Implemented ✅

- [x] SQLite database with GRDB
- [x] User, Board, Pin, Comment models
- [x] Repository pattern
- [x] Dependency injection container
- [x] MVVM architecture
- [x] Plugin system
- [x] Runtime introspection
- [x] Performance monitoring
- [x] Feature flags
- [x] Pin grid view with search
- [x] Modern macOS UI

### Coming Soon 🚧

- [ ] Custom Swift macros (@Query, @Relationship)
- [ ] XPC helper process
- [ ] Client-server architecture
- [ ] Full-text search
- [ ] Image caching
- [ ] Board management
- [ ] User authentication
- [ ] Cloud sync

---

## 📖 Documentation

- **[Main Learning Guide](LEARNING_GUIDE.md)** - Comprehensive tutorial
- **[Dependency Injection](docs/DependencyInjection.md)** - DI system deep dive
- **[Database Schema](docs/DatabaseSchema.md)** - Database design
- **[Plugin Development](docs/PluginDevelopment.md)** - Creating plugins
- **[XPC Communication](docs/XPCCommunication.md)** - Helper processes

---

## 💡 Code Examples

### Creating a Pin

```swift
let pin = Pin(
    boardId: 1,
    title: "Beautiful Design",
    description: "Modern UI concept",
    imageUrl: "https://example.com/image.png"
)

let created = try await pinService.createPin(pin)
print("Created pin with ID: \(created.id)")
```

### Searching Pins

```swift
let results = try await pinService.searchPins(query: "design")
print("Found \(results.count) pins")
```

### Using Plugins

```swift
// Apply vintage filter
let result = try await PluginManager.shared.execute(
    identifier: "com.pinterest.filter.vintage",
    action: .imageFilter(imageData, filterName: "vintage")
)

if case .success(let filteredData) = result {
    // Use filtered image
}
```

---

## 🤝 Contributing

This is a learning project, but contributions are welcome!

1. Fork the repository
2. Create your feature branch
3. Implement with tests
4. Update documentation
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 🙏 Acknowledgments

- **GRDB** - Excellent SQLite toolkit
- **Swift Language** - Modern, safe, and powerful
- **Apple Documentation** - Comprehensive resources
- **Pinterest** - Inspiration for the UI/UX

---

## 📞 Support

- 📖 Check the [Learning Guide](LEARNING_GUIDE.md)
- 💬 Open an issue for questions
- 📧 Contact: your.email@example.com

---

<div align="center">

**Happy Learning! 🎉**

_Remember: The best way to learn is by doing._

[⬆ Back to Top](#pinterest-clone---advanced-swift-learning-project)

</div>
