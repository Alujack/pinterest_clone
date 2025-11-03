//
//  PluginManager.swift
//  pinterest_clone
//
//  Manages plugin lifecycle and execution
//

import Foundation

/// Main manager for plugin system
@MainActor
class PluginManager: ObservableObject {
    // MARK: - Singleton
    static let shared = PluginManager()
    
    // MARK: - Properties
    @Published private(set) var registeredPlugins: [String: PinterestPlugin] = [:]
    @Published private(set) var enabledPlugins: Set<String> = []
    
    private var initializedPlugins: Set<String> = []
    private let pluginQueue = DispatchQueue(label: "com.pinterest.plugin-queue", qos: .userInitiated)
    
    // MARK: - Context
    private let context = PluginContext(
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        environment: .development,
        configuration: [:]
    )
    
    private init() {
        print("🔌 PluginManager initialized")
    }
    
    // MARK: - Registration
    
    /// Register a plugin
    func register(plugin: PinterestPlugin) async throws {
        let identifier = plugin.identifier
        
        guard registeredPlugins[identifier] == nil else {
            throw PluginError.invalidConfiguration
        }
        
        registeredPlugins[identifier] = plugin
        print("✅ Plugin registered: \(plugin.metadata.name) v\(plugin.metadata.version)")
    }
    
    /// Unregister a plugin
    func unregister(identifier: String) async throws {
        if let plugin = registeredPlugins[identifier] {
            try await plugin.cleanup()
            registeredPlugins.removeValue(forKey: identifier)
            enabledPlugins.remove(identifier)
            initializedPlugins.remove(identifier)
            print("🗑️ Plugin unregistered: \(identifier)")
        }
    }
    
    // MARK: - Enable/Disable
    
    /// Enable a plugin
    func enable(identifier: String) async throws {
        guard let plugin = registeredPlugins[identifier] else {
            throw PluginError.notInitialized
        }
        
        if !initializedPlugins.contains(identifier) {
            try await plugin.initialize(context: context)
            initializedPlugins.insert(identifier)
        }
        
        enabledPlugins.insert(identifier)
        print("✅ Plugin enabled: \(plugin.metadata.name)")
    }
    
    /// Disable a plugin
    func disable(identifier: String) {
        enabledPlugins.remove(identifier)
        print("⏸️ Plugin disabled: \(identifier)")
    }
    
    // MARK: - Execution
    
    /// Execute action with specific plugin
    func execute(
        identifier: String,
        action: PluginAction
    ) async throws -> PluginResult {
        guard let plugin = registeredPlugins[identifier] else {
            throw PluginError.notInitialized
        }
        
        guard enabledPlugins.contains(identifier) else {
            throw PluginError.unsupportedCapability
        }
        
        guard plugin.canHandle(action: action) else {
            throw PluginError.invalidAction
        }
        
        return try await plugin.execute(action: action)
    }
    
    /// Execute action with first capable plugin
    func executeWithAnyPlugin(action: PluginAction) async throws -> PluginResult {
        for identifier in enabledPlugins {
            if let plugin = registeredPlugins[identifier],
               plugin.canHandle(action: action) {
                return try await execute(identifier: identifier, action: action)
            }
        }
        
        throw PluginError.unsupportedCapability
    }
    
    /// Execute action with all capable plugins
    func executeWithAllPlugins(action: PluginAction) async throws -> [String: PluginResult] {
        var results: [String: PluginResult] = [:]
        
        for identifier in enabledPlugins {
            if let plugin = registeredPlugins[identifier],
               plugin.canHandle(action: action) {
                do {
                    let result = try await execute(identifier: identifier, action: action)
                    results[identifier] = result
                } catch {
                    results[identifier] = .failure(error: error)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Discovery
    
    /// Load plugins from directory
    func loadPlugins(from directory: URL) async throws {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "plugin" {
                // In real implementation, would load dynamic bundles
                print("📦 Found plugin bundle: \(fileURL.lastPathComponent)")
            }
        }
    }
    
    // MARK: - Query
    
    /// Get plugins by capability
    func plugins(with capability: PluginCapabilities) -> [PinterestPlugin] {
        registeredPlugins.values.filter { plugin in
            plugin.metadata.capabilities.contains(capability)
        }
    }
    
    /// Get enabled plugins
    func enabledPluginsList() -> [PinterestPlugin] {
        enabledPlugins.compactMap { registeredPlugins[$0] }
    }
    
    /// Check if plugin is enabled
    func isEnabled(identifier: String) -> Bool {
        enabledPlugins.contains(identifier)
    }
    
    // MARK: - Cleanup
    
    /// Cleanup all plugins
    func cleanupAll() async {
        for plugin in registeredPlugins.values {
            try? await plugin.cleanup()
        }
        
        registeredPlugins.removeAll()
        enabledPlugins.removeAll()
        initializedPlugins.removeAll()
        
        print("🧹 All plugins cleaned up")
    }
}

// MARK: - Built-in Plugins Registration

extension PluginManager {
    /// Register all built-in plugins
    func registerBuiltInPlugins() async {
        do {
            // Register built-in plugins
            try await register(plugin: VintageFilterPlugin())
            try await register(plugin: JSONExportPlugin())
            try await register(plugin: ImageAnalyticsPlugin())
            
            // Enable by default
            try await enable(identifier: "com.pinterest.filter.vintage")
            try await enable(identifier: "com.pinterest.export.json")
            try await enable(identifier: "com.pinterest.analytics.image")
            
            print("✅ Built-in plugins registered and enabled")
        } catch {
            print("❌ Error registering built-in plugins: \(error)")
        }
    }
}

