# XPC and Client-Server Architecture

## 📖 Overview

This guide explains how to implement **XPC (Cross-Process Communication)** for creating a client-server architecture in macOS apps. XPC allows you to separate your app into multiple processes for better security, stability, and performance.

---

## 🎯 Why Use XPC?

### Benefits

1. **Security** - Sandbox privileged operations
2. **Stability** - Crashes in helper don't affect main app
3. **Performance** - Offload heavy work to background process
4. **Resource Management** - Helper can be terminated when idle
5. **Clean Architecture** - Clear separation of concerns

### Use Cases

- **Image Processing** - Heavy filters and transformations
- **Database Sync** - Background synchronization
- **Network Operations** - Download management
- **File Operations** - Batch file processing
- **Cache Management** - Background cleanup

---

## 🏗️ Architecture Overview

```
┌───────────────────────────────────────────────────────┐
│              Main App (Client)                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │          SwiftUI Views                          │  │
│  │   (User interaction, UI rendering)              │  │
│  └──────────────────┬──────────────────────────────┘  │
│                     │                                  │
│  ┌──────────────────▼──────────────────────────────┐  │
│  │       View Models & Services                    │  │
│  │   (Business logic, state management)            │  │
│  └──────────────────┬──────────────────────────────┘  │
│                     │                                  │
│  ┌──────────────────▼──────────────────────────────┐  │
│  │         XPC Client Wrapper                      │  │
│  │   (Encapsulates XPC communication)              │  │
│  └──────────────────┬──────────────────────────────┘  │
└────────────────────┬────────────────────────────────┘
                     │ XPC Connection
                     │ (NSXPCConnection)
                     │
┌────────────────────▼────────────────────────────────┐
│         Helper Process (Server)                     │
│  ┌─────────────────────────────────────────────────┐ │
│  │       XPC Service Implementation                │ │
│  │   (Implements protocol, receives requests)      │ │
│  └──────────────────┬──────────────────────────────┘ │
│                     │                                 │
│  ┌──────────────────▼──────────────────────────────┐ │
│  │        Business Logic Services                  │ │
│  │   (Image processing, database sync, etc.)       │ │
│  └──────────────────┬──────────────────────────────┘ │
│                     │                                 │
│  ┌──────────────────▼──────────────────────────────┐ │
│  │         Resource Access                         │ │
│  │   (File system, network, database)              │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 🔌 XPC Protocol Definition

### Step 1: Define Shared Protocol

Create a protocol shared between client and server:

```swift
// Shared/PinterestHelperProtocol.swift

import Foundation

/// Protocol defining helper process capabilities
@objc protocol PinterestHelperProtocol {
    /// Process image with filter
    func processImage(
        _ data: Data,
        filterName: String,
        reply: @escaping (Data?, Error?) -> Void
    )
    
    /// Download and cache image
    func downloadImage(
        url: String,
        reply: @escaping (Data?, Error?) -> Void
    )
    
    /// Sync database to cloud
    func syncDatabase(
        localPath: String,
        reply: @escaping (Bool, Error?) -> Void
    )
    
    /// Cleanup cache
    func cleanupCache(
        olderThan: TimeInterval,
        reply: @escaping (Int64, Error?) -> Void
    )
    
    /// Get helper statistics
    func getStatistics(
        reply: @escaping ([String: Any]?, Error?) -> Void
    )
}

/// Helper errors
enum HelperError: Int, Error {
    case invalidInput = 1000
    case processingFailed = 1001
    case networkError = 1002
    case fileSystemError = 1003
    case notAuthorized = 1004
    
    var localizedDescription: String {
        switch self {
        case .invalidInput: return "Invalid input provided"
        case .processingFailed: return "Processing failed"
        case .networkError: return "Network error occurred"
        case .fileSystemError: return "File system error"
        case .notAuthorized: return "Not authorized"
        }
    }
}
```

---

## 🖥️ Client Side Implementation

### XPC Client Wrapper

```swift
// pinterest_clone/Services/XPC/XPCClient.swift

import Foundation

/// Client for communicating with helper process
class XPCClient {
    static let shared = XPCClient()
    
    private var connection: NSXPCConnection?
    private let queue = DispatchQueue(label: "com.pinterest.xpc-client")
    
    private init() {
        setupConnection()
    }
    
    // MARK: - Connection Management
    
    private func setupConnection() {
        connection = NSXPCConnection(serviceName: "com.pinterest.helper")
        
        // Set remote interface
        connection?.remoteObjectInterface = NSXPCInterface(
            with: PinterestHelperProtocol.self
        )
        
        // Set interruption handler
        connection?.interruptionHandler = { [weak self] in
            print("⚠️ XPC connection interrupted")
            self?.handleInterruption()
        }
        
        // Set invalidation handler
        connection?.invalidationHandler = { [weak self] in
            print("❌ XPC connection invalidated")
            self?.connection = nil
        }
        
        // Resume connection
        connection?.resume()
        
        print("✅ XPC connection established")
    }
    
    private func handleInterruption() {
        // Reconnect
        queue.async {
            self.setupConnection()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get remote object proxy
    private func remoteObject() throws -> PinterestHelperProtocol {
        guard let connection = connection else {
            throw HelperError.notAuthorized
        }
        
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
            print("❌ XPC Error: \(error)")
        }) as? PinterestHelperProtocol else {
            throw HelperError.processingFailed
        }
        
        return proxy
    }
    
    // MARK: - Public API
    
    /// Process image with filter
    func processImage(
        _ data: Data,
        filterName: String
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let proxy = try remoteObject()
                
                proxy.processImage(data, filterName: filterName) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let result = result {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: HelperError.processingFailed)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Download image
    func downloadImage(url: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let proxy = try remoteObject()
                
                proxy.downloadImage(url: url) { data, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: HelperError.networkError)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sync database
    func syncDatabase(localPath: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let proxy = try remoteObject()
                
                proxy.syncDatabase(localPath: localPath) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Cleanup cache
    func cleanupCache(olderThan interval: TimeInterval) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let proxy = try remoteObject()
                
                proxy.cleanupCache(olderThan: interval) { bytesFreed, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: bytesFreed)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Get statistics
    func getStatistics() async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let proxy = try remoteObject()
                
                proxy.getStatistics { stats, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let stats = stats {
                        continuation.resume(returning: stats)
                    } else {
                        continuation.resume(returning: [:])
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        connection?.invalidate()
    }
}
```

---

## 🔧 Server Side Implementation

### Helper Process Main

```swift
// PinterestHelper/main.swift

import Foundation

/// Helper process entry point
class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        // Configure connection
        newConnection.exportedInterface = NSXPCInterface(
            with: PinterestHelperProtocol.self
        )
        
        // Set exported object
        newConnection.exportedObject = HelperService()
        
        // Resume connection
        newConnection.resume()
        
        print("✅ Helper: Accepted new connection")
        return true
    }
}

// Start XPC listener
let delegate = HelperDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()

print("🚀 Pinterest Helper Process Started")

// Run forever
RunLoop.main.run()
```

### Helper Service Implementation

```swift
// PinterestHelper/HelperService.swift

import Foundation
import AppKit

/// Implementation of helper service
class HelperService: NSObject, PinterestHelperProtocol {
    
    private let imageProcessor = ImageProcessor()
    private let networkManager = NetworkManager()
    private let cacheManager = CacheManager()
    
    // MARK: - Protocol Implementation
    
    func processImage(
        _ data: Data,
        filterName: String,
        reply: @escaping (Data?, Error?) -> Void
    ) {
        Task {
            do {
                let processed = try await imageProcessor.apply(
                    filter: filterName,
                    to: data
                )
                reply(processed, nil)
            } catch {
                reply(nil, error)
            }
        }
    }
    
    func downloadImage(
        url: String,
        reply: @escaping (Data?, Error?) -> Void
    ) {
        Task {
            do {
                let data = try await networkManager.download(url: url)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }
    
    func syncDatabase(
        localPath: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        Task {
            do {
                try await DatabaseSync.sync(localPath: localPath)
                reply(true, nil)
            } catch {
                reply(false, error)
            }
        }
    }
    
    func cleanupCache(
        olderThan interval: TimeInterval,
        reply: @escaping (Int64, Error?) -> Void
    ) {
        Task {
            do {
                let bytesFreed = try await cacheManager.cleanup(
                    olderThan: interval
                )
                reply(bytesFreed, nil)
            } catch {
                reply(0, error)
            }
        }
    }
    
    func getStatistics(
        reply: @escaping ([String: Any]?, Error?) -> Void
    ) {
        let stats: [String: Any] = [
            "uptime": ProcessInfo.processInfo.systemUptime,
            "memory": getMemoryUsage(),
            "requests_processed": 0 // Track actual requests
        ]
        reply(stats, nil)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}
```

---

## 📦 Project Setup

### 1. Add Helper Target

1. **File > New > Target**
2. Select **XPC Service**
3. Name: `PinterestHelper`
4. Add to project

### 2. Configure Info.plist

```xml
<!-- PinterestHelper/Info.plist -->
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.pinterest.helper</string>
    
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025</string>
    
    <key>XPCService</key>
    <dict>
        <key>ServiceType</key>
        <string>Application</string>
    </dict>
</dict>
```

### 3. Embed XPC Service

1. Select main app target
2. **Build Phases > Embed XPC Services**
3. Add `PinterestHelper.xpc`

---

## 🎯 Usage Examples

### Process Image in Helper

```swift
// In main app
let imageData = // ... load image
let filtered = try await XPCClient.shared.processImage(
    imageData,
    filterName: "vintage"
)
```

### Background Download

```swift
Task {
    do {
        let data = try await XPCClient.shared.downloadImage(
            url: "https://example.com/image.jpg"
        )
        // Save or display image
    } catch {
        print("Download failed: \(error)")
    }
}
```

### Database Sync

```swift
let dbPath = // ... database path
let success = try await XPCClient.shared.syncDatabase(localPath: dbPath)
print("Sync \(success ? "succeeded" : "failed")")
```

---

## 🔒 Security Considerations

### 1. Sandboxing

Helper process runs in restricted sandbox:

```xml
<!-- PinterestHelper.entitlements -->
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Only needed permissions -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
```

### 2. Input Validation

Always validate inputs in helper:

```swift
guard !data.isEmpty else {
    reply(nil, HelperError.invalidInput)
    return
}
```

### 3. Rate Limiting

Prevent abuse:

```swift
private var requestCount = 0
private let maxRequestsPerMinute = 100

func checkRateLimit() throws {
    guard requestCount < maxRequestsPerMinute else {
        throw HelperError.notAuthorized
    }
    requestCount += 1
}
```

---

## 🧪 Testing XPC Services

### Mock XPC Client for Testing

```swift
class MockXPCClient {
    func processImage(_ data: Data, filterName: String) async throws -> Data {
        // Return mock data
        return data
    }
}
```

### Integration Tests

```swift
class XPCIntegrationTests: XCTestCase {
    func testImageProcessing() async throws {
        let client = XPCClient.shared
        let testImage = // ... create test image
        let result = try await client.processImage(
            testImage,
            filterName: "vintage"
        )
        XCTAssertNotNil(result)
    }
}
```

---

## 📊 Monitoring & Debugging

### Helper Logging

```swift
// Use unified logging
import os.log

let log = OSLog(subsystem: "com.pinterest.helper", category: "general")

os_log("Processing image: %@", log: log, type: .info, filterName)
```

### View Console Logs

1. Open **Console.app**
2. Filter by: `com.pinterest.helper`
3. View helper process logs

---

## 🚀 Best Practices

1. **Keep Protocol Simple** - Minimize data transfer
2. **Use Async/Await** - Modern concurrency patterns
3. **Handle Errors Gracefully** - Always provide meaningful errors
4. **Test Thoroughly** - XPC can be tricky to debug
5. **Monitor Performance** - Track request latency
6. **Implement Timeouts** - Prevent hanging operations
7. **Version Protocol** - Allow for future changes

---

## 📚 Further Reading

- [Apple XPC Documentation](https://developer.apple.com/documentation/xpc)
- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [WWDC: XPC and Security](https://developer.apple.com/videos/)

---

**Status:** XPC architecture designed and documented. Implementation requires creating helper target and is left as an advanced exercise.

[⬆ Back to Documentation](../README.md#-documentation)

