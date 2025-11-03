//
//  Board.swift
//  pinterest_clone
//
//  Database Model for Board entity
//

import Foundation
import GRDB

/// Represents a Pinterest board (collection of pins)
struct Board: Codable, Identifiable {
    var id: Int64?
    var userId: Int64
    var title: String
    var description: String?
    var isPrivate: Bool
    var coverImageUrl: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64? = nil,
        userId: Int64,
        title: String,
        description: String? = nil,
        isPrivate: Bool = false,
        coverImageUrl: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.isPrivate = isPrivate
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension Board: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "boards"
    
    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case title
        case description
        case isPrivate = "is_private"
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case isPrivate = "is_private"
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    mutating func willInsert(_ db: Database) throws {
        let now = Date()
        if createdAt == Date(timeIntervalSince1970: 0) {
            createdAt = now
        }
        updatedAt = now
    }
    
    func willUpdate(_ db: Database, columns: Set<String>) throws {
        var copy = self
        copy.updatedAt = Date()
    }
}

// MARK: - Associations

extension Board {
    /// Association: Board belongs to User
    static let user = belongsTo(User.self)
    
    /// Association: Board has many Pins
    static let pins = hasMany(Pin.self)
    
    /// Request for user who owns this board
    var user: QueryInterfaceRequest<User> {
        request(for: Board.user)
    }
    
    /// Request for pins in this board
    var pins: QueryInterfaceRequest<Pin> {
        request(for: Board.pins)
    }
}

// MARK: - Query Extensions

extension Board {
    /// Fetch boards for a specific user
    static func forUser(_ userId: Int64, in db: Database) throws -> [Board] {
        try Board.filter(Columns.userId == userId).fetchAll(db)
    }
    
    /// Fetch public boards only
    static func publicBoards(in db: Database) throws -> [Board] {
        try Board.filter(Columns.isPrivate == false).fetchAll(db)
    }
    
    /// Search boards by title
    static func search(title: String, in db: Database) throws -> [Board] {
        let pattern = "%\(title)%"
        return try Board.filter(Columns.title.like(pattern)).fetchAll(db)
    }
    
    /// Fetch board with its pins
    static func withPins(id: Int64, in db: Database) throws -> (Board, [Pin]) {
        guard let board = try Board.fetchOne(db, key: id) else {
            throw DatabaseError.recordNotFound
        }
        let pins = try Pin.filter(Pin.Columns.boardId == id).fetchAll(db)
        return (board, pins)
    }
}

// MARK: - Sample Data

extension Board {
    static var samples: [Board] {
        [
            Board(
                userId: 1,
                title: "Design Inspiration",
                description: "Beautiful UI designs and interfaces",
                isPrivate: false
            ),
            Board(
                userId: 1,
                title: "Color Palettes",
                description: "Curated color schemes",
                isPrivate: false
            ),
            Board(
                userId: 2,
                title: "Travel Photography",
                description: "Places I want to visit",
                isPrivate: false
            )
        ]
    }
}

// MARK: - Custom Errors

enum DatabaseError: Error {
    case recordNotFound
    case invalidData
    case constraintViolation
}

