//
//  PinGridView.swift
//  pinterest_clone
//
//  Main grid view for displaying pins (Masonry/Waterfall layout)
//

import SwiftUI
import AppKit

struct PinGridView: View {
    @StateObject private var viewModel: PinGridViewModel
    @State private var selectedPin: Pin?
    @State private var showingCreateSheet = false
    
    // Grid configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(viewModel: PinGridViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            // Create ViewModel with DI-resolved service
            let pinService: PinServiceProtocol = Container.shared.resolve()
            _viewModel = StateObject(wrappedValue: PinGridViewModel(pinService: pinService))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar with Create Button
            HStack(spacing: 12) {
                searchBar
                
                Button(action: { showingCreateSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Pin")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            // Content
            ScrollView {
                if viewModel.isLoading && viewModel.pins.isEmpty {
                    loadingView
                } else if viewModel.hasError {
                    errorView
                } else if viewModel.pins.isEmpty {
                    emptyView
                } else {
                    pinsGrid
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .task {
            await viewModel.loadRecentPins()
        }
        .sheet(item: $selectedPin) { pin in
            PinDetailView(pin: pin)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreatePinView { title, description, imageUrl in
                Task {
                    await viewModel.createPin(
                        title: title,
                        description: description,
                        imageUrl: imageUrl
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search pins...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var pinsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.pins) { pin in
                PinCard(pin: pin) {
                    selectedPin = pin
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring(), value: viewModel.pins)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading pins...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(viewModel.errorMessage ?? "An error occurred")
                .foregroundColor(.secondary)
            
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No pins yet")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Start creating pins to see them here")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Pin Detail View

struct PinDetailView: View {
    let pin: Pin
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(pin.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Image
            AsyncImage(url: URL(string: pin.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxHeight: 500)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Description
            if let description = pin.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                if let source = pin.sourceUrl {
                    Label(source, systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Label("Created \(pin.createdAt.formatted())", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 600, height: 700)
    }
}

// MARK: - Preview

#Preview {
    PinGridView(viewModel: .sample)
}

