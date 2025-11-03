//
//  CreatePinView.swift
//  pinterest_clone
//
//  Form to create a new pin
//

import SwiftUI
import AppKit

struct CreatePinView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var imageUrl = ""
    
    let onCreate: (String, String?, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Create New Pin")
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
            
            // Form
            VStack(alignment: .leading, spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                    TextField("Enter pin title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    TextField("Enter description (optional)", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Image URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image URL")
                        .font(.headline)
                    TextField("Enter image URL", text: $imageUrl)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Use https://picsum.photos/seed/yourname/400/600")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quick suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Fill:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("Design") {
                            fillDesignExample()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Photo") {
                            fillPhotoExample()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Art") {
                            fillArtExample()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Pin") {
                    let desc = description.isEmpty ? nil : description
                    onCreate(title, desc, imageUrl)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || imageUrl.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 500, height: 500)
    }
    
    // MARK: - Quick Fill Examples
    
    private func fillDesignExample() {
        title = "Modern UI Design"
        description = "Beautiful and clean interface design"
        imageUrl = "https://picsum.photos/seed/design\(Int.random(in: 1...100))/400/600"
    }
    
    private func fillPhotoExample() {
        title = "Nature Photography"
        description = "Stunning landscape and nature shots"
        imageUrl = "https://picsum.photos/seed/photo\(Int.random(in: 1...100))/600/400"
    }
    
    private func fillArtExample() {
        title = "Digital Art"
        description = "Creative digital artwork and illustrations"
        imageUrl = "https://picsum.photos/seed/art\(Int.random(in: 1...100))/500/700"
    }
}

#Preview {
    CreatePinView { title, desc, url in
        print("Created: \(title)")
    }
}

