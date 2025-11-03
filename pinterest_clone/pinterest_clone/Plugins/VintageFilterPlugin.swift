//
//  VintageFilterPlugin.swift
//  pinterest_clone
//
//  Example plugin: Vintage image filter
//

import Foundation
import AppKit

/// Plugin that applies vintage filter to images
class VintageFilterPlugin: PinterestPlugin {
    var identifier: String {
        metadata.identifier
    }
    
    var metadata: PluginMetadata {
        PluginMetadata(
            identifier: "com.pinterest.filter.vintage",
            name: "Vintage Filter",
            version: "1.0.0",
            author: "Pinterest Clone Team",
            description: "Applies a vintage/retro filter to images",
            capabilities: .imageProcessing,
            icon: "camera.filters"
        )
    }
    
    private var isInitialized = false
    
    func initialize(context: PluginContext) async throws {
        print("🎨 Initializing Vintage Filter Plugin...")
        // Setup any resources needed
        isInitialized = true
    }
    
    func execute(action: PluginAction) async throws -> PluginResult {
        guard isInitialized else {
            throw PluginError.notInitialized
        }
        
        guard case .imageFilter(let data, let filterName) = action,
              filterName == "vintage" else {
            throw PluginError.invalidAction
        }
        
        // Apply vintage filter
        guard let image = NSImage(data: data) else {
            throw PluginError.executionFailed("Invalid image data")
        }
        
        let filtered = applyVintageFilter(to: image)
        
        guard let tiffData = filtered.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw PluginError.executionFailed("Failed to encode filtered image")
        }
        
        return .success(data: pngData)
    }
    
    func cleanup() async throws {
        print("🧹 Cleaning up Vintage Filter Plugin...")
        isInitialized = false
    }
    
    // MARK: - Filter Implementation
    
    private func applyVintageFilter(to image: NSImage) -> NSImage {
        // Simplified vintage filter
        // In real implementation, would use Core Image filters
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Apply sepia tone
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
        
        // Apply vignette
        let vignetteFilter = CIFilter(name: "CIVignette")
        vignetteFilter?.setValue(sepiaFilter?.outputImage, forKey: kCIInputImageKey)
        vignetteFilter?.setValue(1.5, forKey: kCIInputIntensityKey)
        
        guard let outputImage = vignetteFilter?.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        let size = NSSize(width: cgOutput.width, height: cgOutput.height)
        let resultImage = NSImage(cgImage: cgOutput, size: size)
        
        return resultImage
    }
}

