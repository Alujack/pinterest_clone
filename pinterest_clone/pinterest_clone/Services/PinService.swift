//
//  PinService.swift
//  pinterest_clone
//
//  Business logic for Pin operations
//

import Foundation

/// Protocol defining Pin service interface
protocol PinServiceProtocol {
    func getAllPins() async throws -> [Pin]
    func getPin(id: Int64) async throws -> Pin?
    func getRecentPins(limit: Int) async throws -> [Pin]
    func getPinsForBoard(_ boardId: Int64) async throws -> [Pin]
    func searchPins(query: String) async throws -> [Pin]
    func createPin(_ pin: Pin) async throws -> Pin
    func updatePin(_ pin: Pin) async throws
    func deletePin(id: Int64) async throws
}

/// Implementation of Pin service with business logic
class PinService: PinServiceProtocol {
    private let repository: PinRepositoryProtocol
    
    init(repository: PinRepositoryProtocol) {
        self.repository = repository
    }
    
    func getAllPins() async throws -> [Pin] {
        try await repository.fetchAll()
    }
    
    func getPin(id: Int64) async throws -> Pin? {
        try await repository.fetch(id: id)
    }
    
    func getRecentPins(limit: Int = 20) async throws -> [Pin] {
        try await repository.fetchRecent(limit: limit)
    }
    
    func getPinsForBoard(_ boardId: Int64) async throws -> [Pin] {
        try await repository.fetchForBoard(boardId)
    }
    
    func searchPins(query: String) async throws -> [Pin] {
        guard !query.isEmpty else {
            return try await getAllPins()
        }
        return try await repository.search(query: query)
    }
    
    func createPin(_ pin: Pin) async throws -> Pin {
        // Business logic: Validate pin
        guard !pin.title.isEmpty else {
            throw ServiceError.invalidInput("Pin title cannot be empty")
        }
        
        guard !pin.imageUrl.isEmpty else {
            throw ServiceError.invalidInput("Pin must have an image URL")
        }
        
        return try await repository.create(pin)
    }
    
    func updatePin(_ pin: Pin) async throws {
        guard pin.id != nil else {
            throw ServiceError.invalidInput("Pin must have an ID to update")
        }
        
        try await repository.update(pin)
    }
    
    func deletePin(id: Int64) async throws {
        try await repository.delete(id: id)
    }
}

// MARK: - Service Errors

enum ServiceError: LocalizedError {
    case invalidInput(String)
    case notFound(String)
    case unauthorized
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .notFound(let resource):
            return "\(resource) not found"
        case .unauthorized:
            return "Unauthorized access"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

