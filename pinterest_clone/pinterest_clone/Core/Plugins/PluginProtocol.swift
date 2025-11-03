//
//  PluginProtocol.swift
//  pinterest_clone
//
//  Core protocol for plugin system
//

import Foundation

/// Context provided to plugins during initialization
struct PluginContext {
    let appVersion: String
    let environment: Environment
    let configuration: [String: Any]
    
    enum Environment {
        case development
        case production
    }
}

/// Actions that plugins can execute
enum PluginAction {
    case imageFilter(Data, filterName: String)
    case export(Pin, format: ExportFormat)
    case share(Pin, platform: SocialPlatform)
    case customize(theme: String)
    case analyzeImage(Data)
    
    enum ExportFormat: String {
        case json, pdf, html, csv
    }
    
    enum SocialPlatform: String {
        case twitter, facebook, instagram
    }
}

/// Result returned by plugin execution
enum PluginResult {
    case success(data: Any?)
    case failure(error: Error)
    case partial(completed: Int, total: Int)
}

/// Plugin capabilities
struct PluginCapabilities: OptionSet {
    let rawValue: Int
    
    static let imageProcessing = PluginCapabilities(rawValue: 1 << 0)
    static let export = PluginCapabilities(rawValue: 1 << 1)
    static let sharing = PluginCapabilities(rawValue: 1 << 2)
    static let ui = PluginCapabilities(rawValue: 1 << 3)
    static let analytics = PluginCapabilities(rawValue: 1 << 4)
    
    static let all: PluginCapabilities = [.imageProcessing, .export, .sharing, .ui, .analytics]
}

/// Plugin metadata
struct PluginMetadata {
    let identifier: String
    let name: String
    let version: String
    let author: String
    let description: String
    let capabilities: PluginCapabilities
    let icon: String? // SF Symbol name
}

/// Main protocol that all plugins must conform to
protocol PinterestPlugin: AnyObject {
    /// Unique identifier (reverse DNS notation recommended)
    var identifier: String { get }
    
    /// Plugin metadata
    var metadata: PluginMetadata { get }
    
    /// Initialize plugin with context
    func initialize(context: PluginContext) async throws
    
    /// Execute plugin action
    func execute(action: PluginAction) async throws -> PluginResult
    
    /// Cleanup resources
    func cleanup() async throws
    
    /// Check if plugin supports an action
    func canHandle(action: PluginAction) -> Bool
}

// MARK: - Default Implementations

extension PinterestPlugin {
    func cleanup() async throws {
        // Default: no cleanup needed
    }
    
    func canHandle(action: PluginAction) -> Bool {
        // Default: check against capabilities
        switch action {
        case .imageFilter, .analyzeImage:
            return metadata.capabilities.contains(.imageProcessing)
        case .export:
            return metadata.capabilities.contains(.export)
        case .share:
            return metadata.capabilities.contains(.sharing)
        case .customize:
            return metadata.capabilities.contains(.ui)
        }
    }
}

// MARK: - Plugin Errors

enum PluginError: LocalizedError {
    case notInitialized
    case invalidAction
    case unsupportedCapability
    case executionFailed(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Plugin not initialized"
        case .invalidAction:
            return "Invalid action for this plugin"
        case .unsupportedCapability:
            return "Plugin does not support this capability"
        case .executionFailed(let message):
            return "Plugin execution failed: \(message)"
        case .invalidConfiguration:
            return "Invalid plugin configuration"
        }
    }
}

// MARK: - Plugin Discovery

/// Protocol for plugins that can be discovered automatically
protocol AutoDiscoverablePlugin: PinterestPlugin {
    /// URL to plugin bundle
    static var bundleURL: URL { get }
}

