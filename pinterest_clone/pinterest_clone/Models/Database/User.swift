//
//  User.swift
//  pinterest_clone
//
//  Database Model for User entity
//

import Foundation
import GRDB

/// Represents a Pinterest user with full database support
struct User: Codable, Identifiable {
    var id: Int64?
    var username: String
    var email: String
    var avatar: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64? = nil,
        username: String,
        email: String,
        avatar: String? = nil,
        bio: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.avatar = avatar
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension User: FetchableRecord, MutablePersistableRecord {
    /// Database table name
    static let databaseTableName = "users"
    
    /// Define columns for type-safe queries
    enum Columns: String, ColumnExpression {
        case id
        case username
        case email
        case avatar
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Explicit CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case avatar
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Called before insert - generate timestamps
    mutating func willInsert(_ db: Database) throws {
        let now = Date()
        if createdAt == Date(timeIntervalSince1970: 0) {
            createdAt = now
        }
        updatedAt = now
    }
    
    /// Called before update - update timestamp
    func willUpdate(_ db: Database, columns: Set<String>) throws {
        var copy = self
        copy.updatedAt = Date()
    }
}

// MARK: - Associations

extension User {
    /// Association: User has many Boards
    static let boards = hasMany(Board.self)
    
    /// Association: User has many Pins (through comments)
    static let comments = hasMany(Comment.self)
    
    /// Request for boards belonging to this user
    var boards: QueryInterfaceRequest<Board> {
        request(for: User.boards)
    }
    
    /// Request for comments by this user
    var comments: QueryInterfaceRequest<Comment> {
        request(for: User.comments)
    }
}

// MARK: - Query Extensions

extension User {
    /// Find user by email
    static func find(byEmail email: String, in db: Database) throws -> User? {
        try User.filter(Columns.email == email).fetchOne(db)
    }
    
    /// Find user by username
    static func find(byUsername username: String, in db: Database) throws -> User? {
        try User.filter(Columns.username == username).fetchOne(db)
    }
    
    /// Search users by username
    static func search(username: String, in db: Database) throws -> [User] {
        let pattern = "%\(username)%"
        return try User.filter(Columns.username.like(pattern)).fetchAll(db)
    }
}

// MARK: - Sample Data

extension User {
    /// Create sample users for testing and development
    static var samples: [User] {
        [
            User(
                username: "design_master",
                email: "designer@example.com",
                avatar: "person.circle.fill",
                bio: "UI/UX Designer passionate about beautiful interfaces"
            ),
            User(
                username: "photo_lover",
                email: "photo@example.com",
                avatar: "camera.circle.fill",
                bio: "Photography enthusiast sharing my favorite shots"
            ),
            User(
                username: "art_creator",
                email: "artist@example.com",
                avatar: "paintbrush.circle.fill",
                bio: "Digital artist creating inspiring content"
            )
        ]
    }
}

