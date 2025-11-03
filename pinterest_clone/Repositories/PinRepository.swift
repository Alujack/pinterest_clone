//
//  PinRepository.swift
//  pinterest_clone
//
//  Repository pattern for Pin data access
//

import Foundation
import GRDB

/// Protocol defining Pin repository interface
protocol PinRepositoryProtocol {
    func create(_ pin: Pin) async throws -> Pin
    func fetchAll() async throws -> [Pin]
    func fetch(id: Int64) async throws -> Pin?
    func fetchForBoard(_ boardId: Int64) async throws -> [Pin]
    func fetchRecent(limit: Int) async throws -> [Pin]
    func search(query: String) async throws -> [Pin]
    func update(_ pin: Pin) async throws
    func delete(id: Int64) async throws
}

/// Repository implementation for Pins
class PinRepository: PinRepositoryProtocol {
    private let database: DatabaseManager
    
    init(database: DatabaseManager = .shared) {
        self.database = database
    }
    
    // MARK: - CRUD Operations
    
    func create(_ pin: Pin) async throws -> Pin {
        try await database.write { db in
            var mutablePin = pin
            try mutablePin.insert(db)
            return mutablePin
        }
    }
    
    func fetchAll() async throws -> [Pin] {
        try await database.read { db in
            try Pin.order(Pin.Columns.createdAt.desc).fetchAll(db)
        }
    }
    
    func fetch(id: Int64) async throws -> Pin? {
        try await database.read { db in
            try Pin.fetchOne(db, key: id)
        }
    }
    
    func fetchForBoard(_ boardId: Int64) async throws -> [Pin] {
        try await database.read { db in
            try Pin.forBoard(boardId, in: db)
        }
    }
    
    func fetchRecent(limit: Int = 20) async throws -> [Pin] {
        try await database.read { db in
            try Pin.recent(limit: limit, in: db)
        }
    }
    
    func search(query: String) async throws -> [Pin] {
        try await database.read { db in
            try Pin.search(query: query, in: db)
        }
    }
    
    func update(_ pin: Pin) async throws {
        try await database.write { db in
            var mutablePin = pin
            try mutablePin.update(db)
        }
    }
    
    func delete(id: Int64) async throws {
        try await database.write { db in
            try Pin.deleteOne(db, key: id)
        }
    }
    
    // MARK: - Advanced Queries
    
    /// Fetch pin with all related data
    func fetchWithDetails(id: Int64) async throws -> Pin.PinDetail? {
        try await database.read { db in
            try Pin.detail(id: id, in: db)
        }
    }
    
    /// Observe pins in real-time
    func observe() -> AsyncThrowingStream<[Pin], Error> {
        database.observePins()
    }
}

