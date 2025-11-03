//
//  BoardRepository.swift
//  pinterest_clone
//
//  Repository pattern for Board data access
//

import Foundation
import GRDB

/// Protocol defining Board repository interface
protocol BoardRepositoryProtocol {
    func create(_ board: Board) async throws -> Board
    func fetchAll() async throws -> [Board]
    func fetch(id: Int64) async throws -> Board?
    func fetchForUser(_ userId: Int64) async throws -> [Board]
    func fetchPublic() async throws -> [Board]
    func search(title: String) async throws -> [Board]
    func update(_ board: Board) async throws
    func delete(id: Int64) async throws
    func fetchWithPins(id: Int64) async throws -> (Board, [Pin])
}

/// Repository implementation for Boards
class BoardRepository: BoardRepositoryProtocol {
    private let database: DatabaseManager
    
    init(database: DatabaseManager = .shared) {
        self.database = database
    }
    
    // MARK: - CRUD Operations
    
    func create(_ board: Board) async throws -> Board {
        try await database.write { db in
            var mutableBoard = board
            try mutableBoard.insert(db)
            return mutableBoard
        }
    }
    
    func fetchAll() async throws -> [Board] {
        try await database.read { db in
            try Board.order(Board.Columns.createdAt.desc).fetchAll(db)
        }
    }
    
    func fetch(id: Int64) async throws -> Board? {
        try await database.read { db in
            try Board.fetchOne(db, key: id)
        }
    }
    
    func fetchForUser(_ userId: Int64) async throws -> [Board] {
        try await database.read { db in
            try Board.forUser(userId, in: db)
        }
    }
    
    func fetchPublic() async throws -> [Board] {
        try await database.read { db in
            try Board.publicBoards(in: db)
        }
    }
    
    func search(title: String) async throws -> [Board] {
        try await database.read { db in
            try Board.search(title: title, in: db)
        }
    }
    
    func update(_ board: Board) async throws {
        try await database.write { db in
            var mutableBoard = board
            try mutableBoard.update(db)
        }
    }
    
    func delete(id: Int64) async throws {
        try await database.write { db in
            try Board.deleteOne(db, key: id)
        }
    }
    
    // MARK: - Advanced Queries
    
    /// Fetch board with all its pins
    func fetchWithPins(id: Int64) async throws -> (Board, [Pin]) {
        try await database.read { db in
            try Board.withPins(id: id, in: db)
        }
    }
    
    /// Observe boards for a specific user
    func observe(userId: Int64) -> AsyncThrowingStream<[Board], Error> {
        database.observeBoards(userId: userId)
    }
}

