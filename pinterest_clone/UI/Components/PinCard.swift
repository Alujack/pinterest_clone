//
//  PinCard.swift
//  pinterest_clone
//
//  Reusable pin card component
//

import SwiftUI
import AppKit

/// Reusable card component for displaying a pin
struct PinCard: View {
    let pin: Pin
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                AsyncImage(url: URL(string: pin.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.largeTitle)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: calculateHeight())
                .clipped()
                .cornerRadius(12)
                
                // Title
                Text(pin.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Description (optional)
                if let description = pin.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            // Add hover effect
        }
    }
    
    private func calculateHeight() -> CGFloat {
        // Calculate height based on aspect ratio
        guard let width = pin.width, let height = pin.height else {
            return 200 // Default height
        }
        
        let cardWidth: CGFloat = 200 // Approximate card width
        let aspectRatio = CGFloat(height) / CGFloat(width)
        return cardWidth * aspectRatio
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(Pin.samples) { pin in
            PinCard(pin: pin) {
                print("Tapped pin: \(pin.title)")
            }
            .frame(width: 200)
        }
    }
    .padding()
}

