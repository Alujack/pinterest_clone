//
//  Comment.swift
//  pinterest_clone
//
//  Database Model for Comment entity
//

import Foundation
import GRDB

/// Represents a comment on a pin
struct Comment: Codable, Identifiable {
    var id: Int64?
    var pinId: Int64
    var userId: Int64
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64? = nil,
        pinId: Int64,
        userId: Int64,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pinId = pinId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension Comment: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "comments"
    
    enum Columns: String, ColumnExpression {
        case id
        case pinId = "pin_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case pinId = "pin_id"
        case userId = "user_id"
        case content
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

extension Comment {
    /// Association: Comment belongs to Pin
    static let pin = belongsTo(Pin.self)
    
    /// Association: Comment belongs to User
    static let user = belongsTo(User.self)
    
    /// Request for pin this comment belongs to
    var pin: QueryInterfaceRequest<Pin> {
        request(for: Comment.pin)
    }
    
    /// Request for user who wrote this comment
    var user: QueryInterfaceRequest<User> {
        request(for: Comment.user)
    }
}

// MARK: - Query Extensions

extension Comment {
    /// Fetch comments for a specific pin
    static func forPin(_ pinId: Int64, in db: Database) throws -> [Comment] {
        try Comment.filter(Columns.pinId == pinId)
            .order(Columns.createdAt.desc)
            .fetchAll(db)
    }
    
    /// Fetch comments by a specific user
    static func byUser(_ userId: Int64, in db: Database) throws -> [Comment] {
        try Comment.filter(Columns.userId == userId)
            .order(Columns.createdAt.desc)
            .fetchAll(db)
    }
    
    /// Fetch comment with user info
    struct CommentWithUser: Decodable, FetchableRecord {
        var comment: Comment
        var user: User
    }
    
    static func withUser(for pinId: Int64, in db: Database) throws -> [CommentWithUser] {
        let request = Comment
            .filter(Columns.pinId == pinId)
            .including(required: Comment.user)
            .order(Columns.createdAt.desc)
        
        return try Row.fetchAll(db, request).map { row in
            try CommentWithUser(
                comment: try Comment(row: row),
                user: row["user"]
            )
        }
    }
}

// MARK: - Sample Data

extension Comment {
    static var samples: [Comment] {
        [
            Comment(
                pinId: 1,
                userId: 2,
                content: "Love this design! So clean and modern."
            ),
            Comment(
                pinId: 1,
                userId: 3,
                content: "Great color choices! 🎨"
            ),
            Comment(
                pinId: 2,
                userId: 1,
                content: "This is exactly what I was looking for!"
            )
        ]
    }
}

