# Custom Swift Macros Guide

## 📖 Overview

Swift Macros (introduced in Swift 5.9) are a powerful compile-time metaprogramming feature that allows you to generate code automatically. This guide explains how to create and use custom macros in the Pinterest Clone project.

---

## 🎯 What Are Macros?

**Macros** are compile-time code generators that:

- Eliminate boilerplate code
- Ensure type safety
- Provide better error messages
- Run at compile time (zero runtime cost)
- Are fully visible (expanded code can be inspected)

---

## 📚 Types of Macros

### 1. Freestanding Macros

Used like functions, prefixed with `#`:

```swift
#warning("TODO: Implement this feature")
#stringify(1 + 2) // Returns "(1 + 2, 3)"
```

### 2. Attached Macros

Attached to declarations with `@`:

```swift
@Query
@Relationship
@Injectable
@Table("users")
```

---

## 🏗️ Macro Architecture

```
┌─────────────────────────────────────────────────┐
│         Your Code with Macros                   │
│                                                 │
│  @Query(predicate: .recent)                    │
│  var recentPins: [Pin]                         │
└──────────────────┬──────────────────────────────┘
                   │
                   │ Compile Time
                   ▼
┌─────────────────────────────────────────────────┐
│         Swift Compiler                          │
│   [Invokes macro implementation]               │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│      Macro Implementation (Separate Target)     │
│   [SwiftSyntax - Generates code]               │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│           Expanded Code                         │
│                                                 │
│  var recentPins: [Pin] {                       │
│      get async throws {                         │
│          try await repository.fetch(           │
│              predicate: .recent                 │
│          )                                      │
│      }                                          │
│  }                                              │
└─────────────────────────────────────────────────┘
```

---

## 🔨 Creating Custom Macros

### Step 1: Define Macro Declaration

Create a macro declaration in your main target:

```swift
// pinterest_clone/Macros/QueryMacro.swift

/// Query macro for database operations
@attached(accessor)
public macro Query(
    predicate: QueryPredicate = .all,
    limit: Int? = nil,
    orderBy: String? = nil
) = #externalMacro(
    module: "PinterestMacrosPlugin",
    type: "QueryMacro"
)

public enum QueryPredicate {
    case all
    case recent
    case popular
    case custom(String)
}
```

### Step 2: Implement Macro Logic

Create a separate Swift Package for macro implementation:

```swift
// PinterestMacrosPlugin/QueryMacro.swift

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct QueryMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Extract variable name and type
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let type = binding.typeAnnotation?.type else {
            throw MacroError.invalidDeclaration
        }

        // Extract macro arguments
        let arguments = extractArguments(from: node)

        // Generate getter
        let getter: AccessorDeclSyntax = """
            get async throws {
                try await repository.fetch(
                    predicate: .\(raw: arguments.predicate),
                    limit: \(raw: arguments.limit ?? "nil"),
                    orderBy: \(raw: arguments.orderBy ?? "nil")
                )
            }
            """

        return [getter]
    }

    private static func extractArguments(from node: AttributeSyntax) -> Arguments {
        // Parse macro arguments
        // Implementation details...
        return Arguments(predicate: "all", limit: nil, orderBy: nil)
    }
}

enum MacroError: Error {
    case invalidDeclaration
}
```

### Step 3: Register Macro Plugin

```swift
// PinterestMacrosPlugin/Plugin.swift

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PinterestMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        QueryMacro.self,
        RelationshipMacro.self,
        InjectableMacro.self
    ]
}
```

---

## 💉 @Injectable Macro

Automatically register classes in DI container:

### Declaration

```swift
@attached(member, names: named(init))
@attached(extension, conformances: AutoRegistrable)
public macro Injectable(
    lifecycle: ServiceLifecycle = .singleton
) = #externalMacro(
    module: "PinterestMacrosPlugin",
    type: "InjectableMacro"
)
```

### Usage

```swift
@Injectable(lifecycle: .singleton)
class PinService {
    let repository: PinRepositoryProtocol

    // Macro generates:
    // - Automatic DI container registration
    // - Protocol conformance
}
```

### Expansion

```swift
// Expanded by compiler:
extension PinService: AutoRegistrable {
    static var lifecycle: ServiceLifecycle { .singleton }

    static func register(in container: Container) {
        container.register(PinService.self, lifecycle: .singleton) { c in
            PinService()
        }
    }
}
```

---

## 🔗 @Relationship Macro

Define database relationships:

### Declaration

```swift
@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Relationship(
    inverse: KeyPath<Model, Property>? = nil,
    cascade: Bool = true
) = #externalMacro(
    module: "PinterestMacrosPlugin",
    type: "RelationshipMacro"
)
```

### Usage

```swift
struct Board {
    @Relationship(inverse: \Pin.boardId, cascade: true)
    var pins: [Pin]
}
```

### Expansion

```swift
// Expanded by compiler:
struct Board {
    var pins: [Pin] {
        get async throws {
            try await database.read { db in
                try Pin.filter(Column("board_id") == self.id).fetchAll(db)
            }
        }
    }

    // Association metadata
    static let pinsRelationship = hasMany(Pin.self, using: ForeignKey(["board_id"]))
}
```

---

## 📊 @Query Macro

Simplify database queries:

### Usage

```swift
class PinRepository {
    @Query(predicate: .recent, limit: 20)
    var recentPins: [Pin]

    @Query(predicate: .popular, orderBy: "likes DESC")
    var popularPins: [Pin]

    @Query(predicate: .custom("title LIKE '%design%'"))
    var designPins: [Pin]
}
```

### Expansion

```swift
class PinRepository {
    var recentPins: [Pin] {
        get async throws {
            try await database.read { db in
                try Pin.order(Column("createdAt").desc)
                    .limit(20)
                    .fetchAll(db)
            }
        }
    }

    var popularPins: [Pin] {
        get async throws {
            try await database.read { db in
                try Pin.order(sql: "likes DESC")
                    .fetchAll(db)
            }
        }
    }

    var designPins: [Pin] {
        get async throws {
            try await database.read { db in
                try Pin.filter(sql: "title LIKE '%design%'")
                    .fetchAll(db)
            }
        }
    }
}
```

---

## 🎨 @Table Macro

Generate table definitions:

### Usage

```swift
@Table("users")
struct User {
    @Column(primaryKey: true)
    var id: Int64?

    @Column(unique: true)
    var email: String

    var username: String
}
```

### Expansion

```swift
struct User: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "users"

    var id: Int64?
    var email: String
    var username: String

    enum Columns: String, ColumnExpression {
        case id
        case email
        case username
    }

    static func createTable(_ db: Database) throws {
        try db.create(table: "users") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("email", .text).notNull().unique()
            t.column("username", .text).notNull()
        }
    }
}
```

---

## 🧪 Testing Macros

### Unit Tests for Macro Logic

```swift
import XCTest
import SwiftSyntaxMacrosTestSupport

final class QueryMacroTests: XCTestCase {
    func testQueryMacroExpansion() {
        assertMacroExpansion(
            """
            @Query(predicate: .recent, limit: 10)
            var pins: [Pin]
            """,
            expandedSource: """
            var pins: [Pin] {
                get async throws {
                    try await repository.fetch(predicate: .recent, limit: 10)
                }
            }
            """,
            macros: ["Query": QueryMacro.self]
        )
    }
}
```

---

## 🔍 Inspecting Macro Expansions

### In Xcode

1. Right-click on macro usage
2. Select "Expand Macro"
3. View generated code

### Command Line

```bash
# Show macro expansions
swift build --Xswiftc -Xfrontend --Xswiftc -emit-macro-expansion-files

# Find expanded files
find .build -name "*.swiftmacro"
```

---

## 📦 Project Setup for Macros

### 1. Create Macro Target

```
PinterestClone/
├── pinterest_clone/          # Main app
├── PinterestMacros/          # Macro declarations
└── PinterestMacrosPlugin/    # Macro implementations
    └── Package.swift
```

### 2. Package.swift for Macros

```swift
// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PinterestMacros",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "PinterestMacros",
            targets: ["PinterestMacros"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        // Macro implementations
        .macro(
            name: "PinterestMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Macro declarations
        .target(
            name: "PinterestMacros",
            dependencies: ["PinterestMacrosPlugin"]
        ),

        // Tests
        .testTarget(
            name: "PinterestMacrosTests",
            dependencies: [
                "PinterestMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
```

---

## 🎯 Benefits of Macros

| Benefit                 | Description             | Example                            |
| ----------------------- | ----------------------- | ---------------------------------- |
| **Type Safety**         | Compile-time validation | Wrong types caught at compile time |
| **Zero Runtime Cost**   | No performance overhead | Code generated at compile time     |
| **Reduced Boilerplate** | Less code to write      | `@Query` vs manual repository code |
| **Better Errors**       | Clear compile errors    | IDE shows macro expansion          |
| **Refactoring Safety**  | Rename propagates       | Change model, macro updates        |
| **Documentation**       | Self-documenting code   | `@Relationship` shows intent       |

---

## ⚠️ Limitations

1. **Compile Time Only** - Can't generate code at runtime
2. **Syntax Restrictions** - Limited to valid Swift syntax
3. **Learning Curve** - SwiftSyntax is complex
4. **Debugging** - Macro errors can be cryptic
5. **IDE Support** - Still maturing in Xcode

---

## 💡 Best Practices

1. **Keep Macros Simple** - Complex logic should be in regular code
2. **Provide Good Error Messages** - Use `context.diagnose()`
3. **Document Expansions** - Show what code is generated
4. **Test Thoroughly** - Unit test all macro expansions
5. **Use Existing Macros** - Don't reinvent the wheel

---

## 🔗 Resources

- [Swift Macros Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
- [SwiftSyntax Repository](https://github.com/apple/swift-syntax)
- [WWDC 2023: Write Swift Macros](https://developer.apple.com/wwdc23/10166)
- [Swift Evolution: Macros](https://github.com/apple/swift-evolution/blob/main/proposals/0382-expression-macros.md)

---

## 🚀 Future: Implementing Macros in This Project

**Current Status:** Macro architecture designed, implementation pending

**To Implement:**

1. Create `PinterestMacrosPlugin` Swift Package
2. Implement `@Query`, `@Relationship`, `@Injectable` macros
3. Add to project as dependency
4. Use throughout codebase

**Note:** Macros require Swift 5.9+ and are an advanced feature. They're documented here for learning but not critical for the core functionality.

---

**Next Steps:**

- Study SwiftSyntax library
- Practice with simple macros first
- Gradually implement more complex macros
- Test thoroughly before production use

[⬆ Back to Documentation](../README.md#-documentation)
