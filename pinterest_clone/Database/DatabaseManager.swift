//
//  DatabaseManager.swift
//  pinterest_clone
//
//  Core database manager using GRDB
//

import Foundation
import GRDB

/// Main database manager - Singleton pattern with dependency injection support
class DatabaseManager {
    // MARK: - Singleton
    static let shared = DatabaseManager()
    
    // MARK: - Properties
    private var dbQueue: DatabaseQueue!
    private let databaseFileName = "pinterest.sqlite"
    
    // MARK: - Initialization
    
    private init() {
        setupDatabase()
    }
    
    /// Setup database connection and run migrations
    private func setupDatabase() {
        do {
            let databaseURL = try self.databaseURL()
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            
            // Enable foreign keys
            try dbQueue.write { db in
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }
            
            // Run migrations
            try self.runMigrations()
            
            print("✅ Database initialized at: \(databaseURL.path)")
        } catch {
            fatalError("❌ Database setup failed: \(error)")
        }
    }
    
    /// Get database file URL
    private func databaseURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let appFolder = appSupport.appendingPathComponent("PinterestClone", isDirectory: true)
        try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent(databaseFileName)
    }
    
    // MARK: - Migrations
    
    /// Run all database migrations
    private func runMigrations() throws {
        var migrator = DatabaseMigrator()
        
        // Migration v1: Create initial tables
        migrator.registerMigration("v1_initial_schema") { db in
            // Users table
            try db.create(table: "users") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("username", .text).notNull().unique()
                t.column("email", .text).notNull().unique()
                t.column("avatar", .text)
                t.column("bio", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }
            
            // Boards table
            try db.create(table: "boards") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("user_id", .integer)
                    .notNull()
                    .indexed()
                    .references("users", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("description", .text)
                t.column("is_private", .boolean).notNull().defaults(to: false)
                t.column("cover_image_url", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }
            
            // Pins table
            try db.create(table: "pins") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("board_id", .integer)
                    .notNull()
                    .indexed()
                    .references("boards", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("description", .text)
                t.column("image_url", .text).notNull()
                t.column("source_url", .text)
                t.column("width", .integer)
                t.column("height", .integer)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }
            
            // Comments table
            try db.create(table: "comments") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("pin_id", .integer)
                    .notNull()
                    .indexed()
                    .references("pins", onDelete: .cascade)
                t.column("user_id", .integer)
                    .notNull()
                    .indexed()
                    .references("users", onDelete: .cascade)
                t.column("content", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }
            
            print("✅ Migration v1: Initial schema created")
        }
        
        // Migration v2: Add indexes for performance
        migrator.registerMigration("v2_add_indexes") { db in
            try db.create(index: "idx_pins_created_at", on: "pins", columns: ["created_at"])
            try db.create(index: "idx_comments_created_at", on: "comments", columns: ["created_at"])
            try db.create(index: "idx_boards_title", on: "boards", columns: ["title"])
            
            print("✅ Migration v2: Performance indexes created")
        }
        
        // Migration v3: Add full-text search (future)
        migrator.registerMigration("v3_add_fts") { db in
            // Create virtual table for full-text search on pins
            try db.create(virtualTable: "pins_fts", using: FTS5()) { t in
                t.synchronize(withTable: "pins")
                t.column("title")
                t.column("description")
            }
            
            print("✅ Migration v3: Full-text search enabled")
        }
        
        // Apply migrations
        try migrator.migrate(dbQueue)
    }
    
    // MARK: - Database Access
    
    /// Get database queue for direct access
    var database: DatabaseQueue {
        return dbQueue
    }
    
    /// Read from database (async)
    func read<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try dbQueue.read(block)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Write to database (async)
    func write<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try dbQueue.write(block)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sync read (for compatibility)
    func readSync<T>(_ block: (Database) throws -> T) throws -> T {
        try dbQueue.read(block)
    }
    
    /// Sync write (for compatibility)
    func writeSync<T>(_ block: (Database) throws -> T) throws -> T {
        try dbQueue.write(block)
    }
    
    // MARK: - Utilities
    
    /// Seed database with sample data
    func seedSampleData() async throws {
        try await write { db in
            // Insert sample users
            for var user in User.samples {
                try user.insert(db)
            }
            
            // Insert sample boards
            for var board in Board.samples {
                try board.insert(db)
            }
            
            // Insert sample pins
            for var pin in Pin.samples {
                try pin.insert(db)
            }
            
            // Insert sample comments
            for var comment in Comment.samples {
                try comment.insert(db)
            }
            
            print("✅ Sample data seeded successfully")
        }
    }
    
    /// Clear all data from database
    func clearAllData() async throws {
        try await write { db in
            try Comment.deleteAll(db)
            try Pin.deleteAll(db)
            try Board.deleteAll(db)
            try User.deleteAll(db)
            
            print("✅ All data cleared")
        }
    }
    
    /// Get database statistics
    struct DatabaseStats {
        var userCount: Int
        var boardCount: Int
        var pinCount: Int
        var commentCount: Int
        var databaseSizeBytes: Int64
    }
    
    func getStats() async throws -> DatabaseStats {
        try await read { db in
            let users = try User.fetchCount(db)
            let boards = try Board.fetchCount(db)
            let pins = try Pin.fetchCount(db)
            let comments = try Comment.fetchCount(db)
            
            // Get database file size
            let fileURL = try self.databaseURL()
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            
            return DatabaseStats(
                userCount: users,
                boardCount: boards,
                pinCount: pins,
                commentCount: comments,
                databaseSizeBytes: size
            )
        }
    }
    
    /// Export database to JSON (for backup/debugging)
    func exportToJSON() async throws -> Data {
        try await read { db in
            let users = try User.fetchAll(db)
            let boards = try Board.fetchAll(db)
            let pins = try Pin.fetchAll(db)
            let comments = try Comment.fetchAll(db)
            
            let export = [
                "users": users,
                "boards": boards,
                "pins": pins,
                "comments": comments,
                "exportedAt": Date()
            ] as [String : Any]
            
            return try JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
        }
    }
}

// MARK: - Observation Support

extension DatabaseManager {
    /// Observe changes to a specific table
    func observePins() -> AsyncThrowingStream<[Pin], Error> {
        AsyncThrowingStream { continuation in
            let observation = ValueObservation.tracking { db in
                try Pin.order(Pin.Columns.createdAt.desc).fetchAll(db)
            }
            
            let cancellable = observation.start(
                in: dbQueue,
                onError: { error in
                    continuation.finish(throwing: error)
                },
                onChange: { pins in
                    continuation.yield(pins)
                }
            )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Observe boards for a specific user
    func observeBoards(userId: Int64) -> AsyncThrowingStream<[Board], Error> {
        AsyncThrowingStream { continuation in
            let observation = ValueObservation.tracking { db in
                try Board.filter(Board.Columns.userId == userId).fetchAll(db)
            }
            
            let cancellable = observation.start(
                in: dbQueue,
                onError: { error in
                    continuation.finish(throwing: error)
                },
                onChange: { boards in
                    continuation.yield(boards)
                }
            )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

// MARK: - Error Handling

extension DatabaseManager {
    enum DatabaseError: LocalizedError {
        case notInitialized
        case migrationFailed(Error)
        case recordNotFound
        
        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Database not initialized"
            case .migrationFailed(let error):
                return "Migration failed: \(error.localizedDescription)"
            case .recordNotFound:
                return "Record not found in database"
            }
        }
    }
}

