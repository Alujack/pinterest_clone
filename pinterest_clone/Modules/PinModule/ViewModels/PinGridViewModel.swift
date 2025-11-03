//
//  PinGridViewModel.swift
//  pinterest_clone
//
//  ViewModel for Pin Grid using MVVM pattern
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for displaying a grid of pins
@MainActor
class PinGridViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var pins: [Pin] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    // MARK: - Dependencies
    private let pinService: PinServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(pinService: PinServiceProtocol) {
        self.pinService = pinService
        setupSearchObserver()
    }
    
    // MARK: - Public Methods
    
    /// Load all pins
    func loadPins() async {
        isLoading = true
        errorMessage = nil
        
        do {
            pins = try await pinService.getAllPins()
            print("✅ Loaded \(pins.count) pins")
        } catch {
            errorMessage = "Failed to load pins: \(error.localizedDescription)"
            print("❌ Error loading pins: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load recent pins
    func loadRecentPins(limit: Int = 20) async {
        isLoading = true
        errorMessage = nil
        
        do {
            pins = try await pinService.getRecentPins(limit: limit)
            print("✅ Loaded \(pins.count) recent pins")
        } catch {
            errorMessage = "Failed to load recent pins: \(error.localizedDescription)"
            print("❌ Error loading recent pins: \(error)")
        }
        
        isLoading = false
    }
    
    /// Search pins
    func searchPins() async {
        guard !searchQuery.isEmpty else {
            await loadPins()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            pins = try await pinService.searchPins(query: searchQuery)
            print("✅ Found \(pins.count) pins matching '\(searchQuery)'")
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            print("❌ Error searching pins: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh pins
    func refresh() async {
        await loadPins()
    }
    
    /// Create a new pin
    func createPin(title: String, description: String?, imageUrl: String, boardId: Int64 = 1) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newPin = Pin(
                boardId: boardId,
                title: title,
                description: description,
                imageUrl: imageUrl,
                width: 400,
                height: 600
            )
            
            let created = try await pinService.createPin(newPin)
            print("✅ Created new pin: \(created.title)")
            
            // Refresh the pins list
            await loadPins()
        } catch {
            errorMessage = "Failed to create pin: \(error.localizedDescription)"
            print("❌ Error creating pin: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupSearchObserver() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.searchPins()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var hasError: Bool {
        errorMessage != nil
    }
}

// MARK: - Sample for Previews

#if DEBUG
extension PinGridViewModel {
    static var sample: PinGridViewModel {
        let mockService = MockPinService()
        let viewModel = PinGridViewModel(pinService: mockService)
        viewModel.pins = Pin.samples
        return viewModel
    }
}

class MockPinService: PinServiceProtocol {
    var pins: [Pin] = Pin.samples
    
    func getAllPins() async throws -> [Pin] { pins }
    func getPin(id: Int64) async throws -> Pin? { pins.first }
    func getRecentPins(limit: Int) async throws -> [Pin] { Array(pins.prefix(limit)) }
    func getPinsForBoard(_ boardId: Int64) async throws -> [Pin] { pins }
    func searchPins(query: String) async throws -> [Pin] { pins }
    func createPin(_ pin: Pin) async throws -> Pin { pin }
    func updatePin(_ pin: Pin) async throws { }
    func deletePin(id: Int64) async throws { }
}
#endif

