//
//  Pin.swift
//  pinterest_clone
//
//  Database Model for Pin entity
//

import Foundation
import GRDB

/// Represents a Pinterest pin (image/content)
struct Pin: Codable, Identifiable, Equatable {
    var id: Int64?
    var boardId: Int64
    var title: String
    var description: String?
    var imageUrl: String
    var sourceUrl: String?
    var width: Int?
    var height: Int?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64? = nil,
        boardId: Int64,
        title: String,
        description: String? = nil,
        imageUrl: String,
        sourceUrl: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.boardId = boardId
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.sourceUrl = sourceUrl
        self.width = width
        self.height = height
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension Pin: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "pins"
    
    enum Columns: String, ColumnExpression {
        case id
        case boardId = "board_id"
        case title
        case description
        case imageUrl = "image_url"
        case sourceUrl = "source_url"
        case width
        case height
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Explicit CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case title
        case description
        case imageUrl = "image_url"
        case sourceUrl = "source_url"
        case width
        case height
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

extension Pin {
    /// Association: Pin belongs to Board
    static let board = belongsTo(Board.self)
    
    /// Association: Pin has many Comments
    static let comments = hasMany(Comment.self)
    
    /// Request for board containing this pin
    var board: QueryInterfaceRequest<Board> {
        request(for: Pin.board)
    }
    
    /// Request for comments on this pin
    var comments: QueryInterfaceRequest<Comment> {
        request(for: Pin.comments)
    }
}

// MARK: - Query Extensions

extension Pin {
    /// Fetch pins for a specific board
    static func forBoard(_ boardId: Int64, in db: Database) throws -> [Pin] {
        try Pin.filter(Columns.boardId == boardId)
            .order(Columns.createdAt.desc)
            .fetchAll(db)
    }
    
    /// Fetch recent pins across all boards
    static func recent(limit: Int = 20, in db: Database) throws -> [Pin] {
        try Pin.order(Columns.createdAt.desc)
            .limit(limit)
            .fetchAll(db)
    }
    
    /// Search pins by title or description
    static func search(query: String, in db: Database) throws -> [Pin] {
        let pattern = "%\(query)%"
        return try Pin.filter(
            Columns.title.like(pattern) || Columns.description.like(pattern)
        ).fetchAll(db)
    }
    
    /// Fetch pin with its comments and board info
    struct PinDetail: Decodable, FetchableRecord {
        var pin: Pin
        var board: Board
        var comments: [Comment]
    }
    
    static func detail(id: Int64, in db: Database) throws -> PinDetail? {
        guard let pin = try Pin.fetchOne(db, key: id) else {
            return nil
        }
        
        let board = try pin.board.fetchOne(db)!
        let comments = try pin.comments.fetchAll(db)
        
        return PinDetail(pin: pin, board: board, comments: comments)
    }
}

// MARK: - Computed Properties

extension Pin {
    /// Calculate aspect ratio for layout
    var aspectRatio: Double? {
        guard let width = width, let height = height, height > 0 else {
            return nil
        }
        return Double(width) / Double(height)
    }
    
    /// Check if pin is landscape
    var isLandscape: Bool {
        guard let ratio = aspectRatio else { return false }
        return ratio > 1.0
    }
    
    /// Check if pin is portrait
    var isPortrait: Bool {
        guard let ratio = aspectRatio else { return false }
        return ratio < 1.0
    }
}

// MARK: - Sample Data

extension Pin {
    static var samples: [Pin] {
        [
            Pin(
                boardId: 1,
                title: "Modern Dashboard Design",
                description: "Clean and minimal dashboard interface with beautiful gradients",
                imageUrl: "https://picsum.photos/seed/dash1/400/600",
                sourceUrl: "https://dribbble.com",
                width: 400,
                height: 600
            ),
            Pin(
                boardId: 1,
                title: "Mobile App UI",
                description: "Beautiful mobile application design with modern aesthetics",
                imageUrl: "https://picsum.photos/seed/mobile1/400/800",
                sourceUrl: "https://behance.net",
                width: 400,
                height: 800
            ),
            Pin(
                boardId: 2,
                title: "Sunset Color Palette",
                description: "Warm and vibrant colors inspired by nature",
                imageUrl: "https://picsum.photos/seed/sunset1/600/400",
                width: 600,
                height: 400
            ),
            Pin(
                boardId: 3,
                title: "Mountain Landscape",
                description: "Breathtaking mountain view photography",
                imageUrl: "https://picsum.photos/seed/mountain1/800/600",
                width: 800,
                height: 600
            ),
            Pin(
                boardId: 1,
                title: "Minimalist Web Design",
                description: "Less is more - clean web interface concept",
                imageUrl: "https://picsum.photos/seed/web1/500/700",
                width: 500,
                height: 700
            ),
            Pin(
                boardId: 2,
                title: "Typography Inspiration",
                description: "Creative font combinations and layouts",
                imageUrl: "https://picsum.photos/seed/typo1/600/800",
                width: 600,
                height: 800
            ),
            Pin(
                boardId: 1,
                title: "Dark Mode Interface",
                description: "Sleek dark-themed UI design",
                imageUrl: "https://picsum.photos/seed/dark1/450/650",
                width: 450,
                height: 650
            ),
            Pin(
                boardId: 3,
                title: "Nature Photography",
                description: "Beautiful landscapes and natural scenes",
                imageUrl: "https://picsum.photos/seed/nature1/700/500",
                width: 700,
                height: 500
            ),
            Pin(
                boardId: 2,
                title: "Brand Identity",
                description: "Complete branding package design",
                imageUrl: "https://picsum.photos/seed/brand1/550/750",
                width: 550,
                height: 750
            ),
            Pin(
                boardId: 1,
                title: "3D Illustration",
                description: "Modern 3D design elements and illustrations",
                imageUrl: "https://picsum.photos/seed/3d1/400/550",
                width: 400,
                height: 550
            ),
            Pin(
                boardId: 3,
                title: "Urban Architecture",
                description: "Modern city buildings and structures",
                imageUrl: "https://picsum.photos/seed/urban1/600/900",
                width: 600,
                height: 900
            ),
            Pin(
                boardId: 2,
                title: "Geometric Patterns",
                description: "Abstract geometric design patterns",
                imageUrl: "https://picsum.photos/seed/geo1/500/500",
                width: 500,
                height: 500
            )
        ]
    }
}

