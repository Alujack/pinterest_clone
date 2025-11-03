//
//  Container.swift
//  pinterest_clone
//
//  Dependency Injection Container
//

import Foundation

/// Service lifecycle scope
enum ServiceLifecycle {
    case singleton  // One instance for entire app
    case transient  // New instance every time
    case scoped     // One instance per scope (e.g., per view hierarchy)
}

/// Type-erased factory closure
private class ServiceFactory {
    let lifecycle: ServiceLifecycle
    let factory: (Container) -> Any
    var instance: Any?
    
    init(lifecycle: ServiceLifecycle, factory: @escaping (Container) -> Any) {
        self.lifecycle = lifecycle
        self.factory = factory
    }
}

/// Main dependency injection container
class Container {
    // MARK: - Singleton
    static let shared = Container()
    
    // MARK: - Properties
    private var services: [String: ServiceFactory] = [:]
    private let lock = NSRecursiveLock()
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register a service with a factory closure
    func register<T>(
        _ serviceType: T.Type,
        lifecycle: ServiceLifecycle = .singleton,
        factory: @escaping (Container) -> T
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: serviceType)
        services[key] = ServiceFactory(lifecycle: lifecycle) { container in
            factory(container)
        }
        
        print("📦 Registered: \(key) [\(lifecycle)]")
    }
    
    /// Register a singleton instance directly
    func registerSingleton<T>(_ serviceType: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: serviceType)
        let serviceFactory = ServiceFactory(lifecycle: .singleton) { _ in instance }
        serviceFactory.instance = instance
        services[key] = serviceFactory
        
        print("📦 Registered singleton: \(key)")
    }
    
    // MARK: - Resolution
    
    /// Resolve a service instance
    func resolve<T>(_ serviceType: T.Type = T.self) -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: serviceType)
        
        guard let serviceFactory = services[key] else {
            fatalError("❌ Service not registered: \(key)")
        }
        
        // Handle lifecycle
        switch serviceFactory.lifecycle {
        case .singleton:
            if let instance = serviceFactory.instance as? T {
                return instance
            }
            let instance = serviceFactory.factory(self) as! T
            serviceFactory.instance = instance
            return instance
            
        case .transient, .scoped:
            return serviceFactory.factory(self) as! T
        }
    }
    
    /// Try to resolve a service (returns nil if not registered)
    func tryResolve<T>(_ serviceType: T.Type = T.self) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: serviceType)
        guard let serviceFactory = services[key] else {
            return nil
        }
        
        switch serviceFactory.lifecycle {
        case .singleton:
            if let instance = serviceFactory.instance as? T {
                return instance
            }
            let instance = serviceFactory.factory(self) as! T
            serviceFactory.instance = instance
            return instance
            
        case .transient, .scoped:
            return serviceFactory.factory(self) as? T
        }
    }
    
    // MARK: - Utilities
    
    /// Clear all registrations (useful for testing)
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        print("🗑️ Container reset")
    }
    
    /// List all registered services
    func listServices() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(services.keys)
    }
    
    /// Check if service is registered
    func isRegistered<T>(_ serviceType: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: serviceType)
        return services[key] != nil
    }
}

// MARK: - Property Wrapper for Injection

/// Property wrapper for automatic dependency injection
@propertyWrapper
struct Injected<T> {
    private var service: T
    
    init() {
        self.service = Container.shared.resolve(T.self)
    }
    
    var wrappedValue: T {
        get { service }
        mutating set { service = newValue }
    }
    
    var projectedValue: Injected<T> {
        get { self }
        set { self = newValue }
    }
}

/// Property wrapper for optional dependency injection
@propertyWrapper
struct OptionalInjected<T> {
    private var service: T?
    
    init() {
        self.service = Container.shared.tryResolve(T.self)
    }
    
    var wrappedValue: T? {
        get { service }
        mutating set { service = newValue }
    }
}

// MARK: - Auto-Registration Protocol

/// Protocol for services that can auto-register themselves
protocol AutoRegistrable {
    static var lifecycle: ServiceLifecycle { get }
    static func register(in container: Container)
}

extension AutoRegistrable {
    static var lifecycle: ServiceLifecycle { .singleton }
}

// MARK: - Module Protocol

/// Protocol for organizing service registration into modules
protocol DIModule {
    func registerServices(in container: Container)
}

// MARK: - Debug Utilities

extension Container {
    /// Print dependency tree for debugging
    func printDependencyTree() {
        print("\n📊 Dependency Container Status:")
        print("================================")
        
        let serviceList = listServices().sorted()
        for service in serviceList {
            if let factory = services[service] {
                let lifecycleEmoji = factory.lifecycle == .singleton ? "🔒" : "🔄"
                let instanceStatus = factory.instance != nil ? "✅" : "⏳"
                print("\(lifecycleEmoji) \(service) [\(instanceStatus)]")
            }
        }
        
        print("================================")
        print("Total services: \(services.count)\n")
    }
}

// MARK: - Testing Support

#if DEBUG
extension Container {
    /// Create a test container with mocked services
    static func test() -> Container {
        let container = Container()
        return container
    }
    
    /// Register mock for testing
    func registerMock<T>(_ serviceType: T.Type, mock: T) {
        registerSingleton(serviceType, instance: mock)
    }
}
#endif

