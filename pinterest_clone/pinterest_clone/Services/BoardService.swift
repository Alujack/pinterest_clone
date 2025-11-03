//
//  BoardService.swift
//  pinterest_clone
//
//  Business logic for Board operations
//

import Foundation

/// Protocol defining Board service interface
protocol BoardServiceProtocol {
    func getAllBoards() async throws -> [Board]
    func getBoard(id: Int64) async throws -> Board?
    func getBoardsForUser(_ userId: Int64) async throws -> [Board]
    func getPublicBoards() async throws -> [Board]
    func searchBoards(title: String) async throws -> [Board]
    func createBoard(_ board: Board) async throws -> Board
    func updateBoard(_ board: Board) async throws
    func deleteBoard(id: Int64) async throws
    func getBoardWithPins(id: Int64) async throws -> (Board, [Pin])
}

/// Implementation of Board service with business logic
class BoardService: BoardServiceProtocol {
    private let repository: BoardRepositoryProtocol
    
    init(repository: BoardRepositoryProtocol) {
        self.repository = repository
    }
    
    func getAllBoards() async throws -> [Board] {
        try await repository.fetchAll()
    }
    
    func getBoard(id: Int64) async throws -> Board? {
        try await repository.fetch(id: id)
    }
    
    func getBoardsForUser(_ userId: Int64) async throws -> [Board] {
        try await repository.fetchForUser(userId)
    }
    
    func getPublicBoards() async throws -> [Board] {
        try await repository.fetchPublic()
    }
    
    func searchBoards(title: String) async throws -> [Board] {
        guard !title.isEmpty else {
            return try await getAllBoards()
        }
        return try await repository.search(title: title)
    }
    
    func createBoard(_ board: Board) async throws -> Board {
        // Business logic: Validate board
        guard !board.title.isEmpty else {
            throw ServiceError.invalidInput("Board title cannot be empty")
        }
        
        return try await repository.create(board)
    }
    
    func updateBoard(_ board: Board) async throws {
        guard board.id != nil else {
            throw ServiceError.invalidInput("Board must have an ID to update")
        }
        
        try await repository.update(board)
    }
    
    func deleteBoard(id: Int64) async throws {
        try await repository.delete(id: id)
    }
    
    func getBoardWithPins(id: Int64) async throws -> (Board, [Pin]) {
        try await repository.fetchWithPins(id: id)
    }
}

