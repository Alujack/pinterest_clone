//
//  RuntimeInspector.swift
//  pinterest_clone
//
//  Runtime introspection and reflection utilities
//

import Foundation

/// Utility for runtime introspection using Swift's Mirror API
class RuntimeInspector {
    /// Inspect any object and print its structure
    static func inspect(_ object: Any, depth: Int = 0) {
        let mirror = Mirror(reflecting: object)
        let indent = String(repeating: "  ", count: depth)
        
        print("\(indent)📦 Type: \(type(of: object))")
        
        if let displayStyle = mirror.displayStyle {
            print("\(indent)   Style: \(displayStyle)")
        }
        
        guard mirror.children.count > 0 else {
            print("\(indent)   Value: \(object)")
            return
        }
        
        print("\(indent)   Properties:")
        for child in mirror.children {
            let label = child.label ?? "unnamed"
            let value = child.value
            print("\(indent)   - \(label): \(type(of: value))")
            
            // Recursively inspect complex types
            if depth < 2 {
                inspect(value, depth: depth + 1)
            }
        }
    }
    
    /// Get all property names of an object
    static func propertyNames(of object: Any) -> [String] {
        let mirror = Mirror(reflecting: object)
        return mirror.children.compactMap { $0.label }
    }
    
    /// Get property value by name using key path
    static func value<T, V>(for keyPath: KeyPath<T, V>, in object: T) -> V {
        return object[keyPath: keyPath]
    }
    
    /// Get all properties as dictionary
    static func toDictionary(_ object: Any) -> [String: Any] {
        let mirror = Mirror(reflecting: object)
        var dict: [String: Any] = [:]
        
        for child in mirror.children {
            if let label = child.label {
                dict[label] = child.value
            }
        }
        
        return dict
    }
    
    /// Check if type conforms to protocol
    static func conforms(type: Any.Type, to protocolType: Protocol) -> Bool {
        // Note: Swift doesn't provide direct protocol conformance checking at runtime
        // This is a simplified implementation
        return true // Placeholder - real implementation would use reflection
    }
}

// MARK: - Dynamic Property Access

/// Property wrapper for dynamic property access
@propertyWrapper
struct Dynamic<Value> {
    private var storage: Value
    private var observers: [(Value) -> Void] = []
    
    init(wrappedValue: Value) {
        self.storage = wrappedValue
    }
    
    var wrappedValue: Value {
        get { storage }
        set {
            storage = newValue
            observers.forEach { $0(newValue) }
        }
    }
    
    mutating func observe(_ observer: @escaping (Value) -> Void) {
        observers.append(observer)
    }
}

// MARK: - Type Information

struct TypeInfo {
    let name: String
    let moduleName: String
    let kind: TypeKind
    let properties: [PropertyInfo]
    
    enum TypeKind {
        case `class`
        case `struct`
        case `enum`
        case `protocol`
        case other
    }
    
    struct PropertyInfo {
        let name: String
        let type: String
    }
    
    static func of(_ type: Any.Type) -> TypeInfo {
        let fullName = String(describing: type)
        let components = fullName.split(separator: ".")
        
        let moduleName = components.count > 1 ? String(components[0]) : "Unknown"
        let typeName = components.count > 1 ? String(components[1]) : fullName
        
        // Determine kind (simplified)
        let kind: TypeKind
        if String(describing: type).contains("class") {
            kind = .class
        } else if String(describing: type).contains("struct") {
            kind = .struct
        } else if String(describing: type).contains("enum") {
            kind = .enum
        } else if String(describing: type).contains("protocol") {
            kind = .protocol
        } else {
            kind = .other
        }
        
        return TypeInfo(
            name: typeName,
            moduleName: moduleName,
            kind: kind,
            properties: []
        )
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var metrics: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "com.pinterest.performance")
    
    /// Measure execution time of a block
    func measure<T>(name: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            recordMetric(name: name, duration: duration)
        }
        return try block()
    }
    
    /// Measure async execution time
    func measure<T>(name: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            recordMetric(name: name, duration: duration)
        }
        return try await block()
    }
    
    private func recordMetric(name: String, duration: TimeInterval) {
        queue.async {
            self.metrics[name, default: []].append(duration)
            
            #if DEBUG
            if duration > 0.1 { // Log slow operations
                print("⚠️ Slow operation '\(name)': \(String(format: "%.3f", duration))s")
            }
            #endif
        }
    }
    
    /// Get statistics for a metric
    func statistics(for name: String) -> MetricStatistics? {
        queue.sync {
            guard let durations = metrics[name], !durations.isEmpty else {
                return nil
            }
            
            let sorted = durations.sorted()
            let count = durations.count
            let sum = durations.reduce(0, +)
            
            return MetricStatistics(
                name: name,
                count: count,
                min: sorted.first!,
                max: sorted.last!,
                average: sum / Double(count),
                median: sorted[count / 2]
            )
        }
    }
    
    /// Print all statistics
    func printStatistics() {
        queue.sync {
            print("\n Performance Statistics:")
            print("=" + String(repeating: "=", count: 60))
            
            for name in metrics.keys.sorted() {
                if let stats = statistics(for: name) {
                    print(String(format: "%-30s: %.3fs (avg), %.3fs (min), %.3fs (max), %d calls",
                                 name, stats.average, stats.min, stats.max, stats.count))
                }
            }
            
            print("=" + String(repeating: "=", count: 60) + "\n")
        }
    }
    
    struct MetricStatistics {
        let name: String
        let count: Int
        let min: TimeInterval
        let max: TimeInterval
        let average: TimeInterval
        let median: TimeInterval
    }
}

// MARK: - Feature Flags

class FeatureFlags {
    static let shared = FeatureFlags()
    
    private var flags: [String: Bool] = [:]
    
    /// Define feature flags
    enum Feature: String {
        case experimentalUI = "experimental_ui"
        case advancedSearch = "advanced_search"
        case imageFilters = "image_filters"
        case pluginSystem = "plugin_system"
        case betaFeatures = "beta_features"
    }
    
    /// Check if feature is enabled
    func isEnabled(_ feature: Feature) -> Bool {
        #if DEBUG
        // In development, check user defaults
        return UserDefaults.standard.bool(forKey: feature.rawValue)
        #else
        // In production, use stored flags
        return flags[feature.rawValue, default: false]
        #endif
    }
    
    /// Set feature flag (development only)
    #if DEBUG
    func setEnabled(_ feature: Feature, _ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: feature.rawValue)
        print("🚩 Feature '\(feature.rawValue)' \(enabled ? "enabled" : "disabled")")
    }
    #endif
    
    /// Load flags from remote config
    func loadRemoteFlags() async {
        // In real app, would fetch from server
        flags = [
            Feature.pluginSystem.rawValue: true,
            Feature.advancedSearch.rawValue: true,
            Feature.imageFilters.rawValue: false
        ]
    }
}

// MARK: - Runtime Examples

class RuntimeExamples {
    /// Demonstrate reflection
    static func demonstrateReflection() {
        print("\n🔍 Runtime Reflection Demo")
        print("=" + String(repeating: "=", count: 60))
        
        let pin = Pin.samples.first!
        
        print("\n1. Inspecting Pin object:")
        RuntimeInspector.inspect(pin)
        
        print("\n2. Property names:")
        let properties = RuntimeInspector.propertyNames(of: pin)
        print(properties.joined(separator: ", "))
        
        print("\n3. As dictionary:")
        let dict = RuntimeInspector.toDictionary(pin)
        dict.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        print("\n4. Type information:")
        let typeInfo = TypeInfo.of(Pin.self)
        print("  Name: \(typeInfo.name)")
        print("  Module: \(typeInfo.moduleName)")
        print("  Kind: \(typeInfo.kind)")
        
        print("=" + String(repeating: "=", count: 60) + "\n")
    }
    
    /// Demonstrate performance monitoring
    static func demonstratePerformance() async {
        print("\n⚡ Performance Monitoring Demo")
        print("=" + String(repeating: "=", count: 60))
        
        let monitor = PerformanceMonitor.shared
        
        // Measure synchronous work
        _ = monitor.measure(name: "array_sort") {
            let numbers = (1...1000).shuffled()
            return numbers.sorted()
        }
        
        // Measure async work
        _ = await monitor.measure(name: "async_task") {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            return "Done"
        }
        
        // Measure database query
        _ = monitor.measure(name: "sample_computation") {
            var sum = 0
            for i in 1...10000 {
                sum += i
            }
            return sum
        }
        
        // Print statistics
        monitor.printStatistics()
        
        print("=" + String(repeating: "=", count: 60) + "\n")
    }
    
    /// Demonstrate feature flags
    static func demonstrateFeatureFlags() {
        print("\n🚩 Feature Flags Demo")
        print("=" + String(repeating: "=", count: 60))
        
        let flags = FeatureFlags.shared
        
        #if DEBUG
        // Set some flags
        flags.setEnabled(.experimentalUI, true)
        flags.setEnabled(.advancedSearch, true)
        flags.setEnabled(.imageFilters, false)
        #endif
        
        // Check flags
        print("\nFeature Status:")
        print("  Experimental UI: \(flags.isEnabled(.experimentalUI) ? "✅" : "❌")")
        print("  Advanced Search: \(flags.isEnabled(.advancedSearch) ? "✅" : "❌")")
        print("  Image Filters: \(flags.isEnabled(.imageFilters) ? "✅" : "❌")")
        print("  Plugin System: \(flags.isEnabled(.pluginSystem) ? "✅" : "❌")")
        
        print("=" + String(repeating: "=", count: 60) + "\n")
    }
}

