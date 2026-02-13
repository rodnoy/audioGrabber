//
//  MetadataEditorViewModel.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import Foundation
import SwiftUI
import AppKit

@MainActor
@Observable
final class MetadataEditorViewModel {
    // MARK: - State
    
    var selectedFileURL: URL?
    var metadata: AudioFileMetadata?
    var originalMetadata: AudioFileMetadata?
    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?
    var successMessage: String?
    
    var hasUnsavedChanges: Bool {
        guard let metadata = metadata, let originalMetadata = originalMetadata else {
            return false
        }
        return metadata != originalMetadata
    }
    
    // MARK: - Security-Scoped Resources
    
    private var isAccessingSecurityScopedResource: Bool = false
    
    // MARK: - Services
    
    private let metadataService: MetadataServiceProtocol
    
    // MARK: - Initialization
    
    init(metadataService: MetadataServiceProtocol) {
        self.metadataService = metadataService
    }
    
    // MARK: - Actions
    
    /// Open file picker to select an audio file
    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .mp3]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select an audio file to edit metadata"
        
        if panel.runModal() == .OK, let url = panel.url {
            // NSOpenPanel automatically provides security-scoped access
            Task {
                await loadFile(from: url)
            }
        }
    }
    
    /// Load audio file and read its metadata
    func loadFile(from url: URL) async {
        // Stop accessing previous security-scoped resource if any
        stopAccessingSecurityScopedResource()
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Start accessing the security-scoped resource
        // This is needed for both drag-and-drop and file picker URLs
        isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
        
        do {
            let loadedMetadata = try await metadataService.readMetadata(from: url)
            self.metadata = loadedMetadata
            self.originalMetadata = loadedMetadata
            self.selectedFileURL = url
            self.successMessage = "File loaded successfully"
        } catch {
            self.errorMessage = "Failed to load file: \(error.localizedDescription)"
            self.metadata = nil
            self.originalMetadata = nil
            self.selectedFileURL = nil
            stopAccessingSecurityScopedResource()
        }
        
        isLoading = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            Task {
                try? await Task.sleep(for: .seconds(3))
                self.successMessage = nil
            }
        }
    }
    
    /// Save changes to the audio file
    func saveChanges() async {
        guard let url = selectedFileURL, let metadata = metadata else {
            errorMessage = "No file selected or metadata available"
            return
        }
        
        // Show NSSavePanel to choose where to save the modified file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mpeg4Audio]
        savePanel.nameFieldStringValue = url.lastPathComponent
        savePanel.message = "Choose where to save the modified file"
        savePanel.canCreateDirectories = true
        
        guard savePanel.runModal() == .OK, let saveURL = savePanel.url else {
            // User cancelled
            return
        }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await metadataService.writeMetadata(metadata, to: url, outputURL: saveURL)
            self.originalMetadata = metadata
            self.successMessage = "Metadata saved successfully to \(saveURL.lastPathComponent)"
        } catch {
            self.errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
        
        isSaving = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            Task {
                try? await Task.sleep(for: .seconds(3))
                self.successMessage = nil
            }
        }
    }
    
    /// Discard unsaved changes
    func discardChanges() {
        metadata = originalMetadata
        errorMessage = nil
        successMessage = nil
    }
    
    /// Clear the current file and release security-scoped access
    func clearFile() {
        stopAccessingSecurityScopedResource()
        selectedFileURL = nil
        metadata = nil
        originalMetadata = nil
        errorMessage = nil
        successMessage = nil
    }
    
    /// Export artwork to a directory
    func exportArtwork(to directory: URL) async throws -> URL? {
        guard let metadata = metadata, let image = metadata.artwork else {
            throw NSError(
                domain: "MetadataEditorViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No artwork available"]
            )
        }
        
        // Determine file extension based on image format
        let fileExtension: String
        if let rep = image.representations.first {
            if rep is NSBitmapImageRep {
                fileExtension = "png"
            } else {
                fileExtension = "jpg"
            }
        } else {
            fileExtension = "png"
        }
        
        // Create filename from metadata
        let filename: String
        if let artist = metadata.artist, let title = metadata.title {
            let sanitized = "\(artist) - \(title)"
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            filename = "\(sanitized).\(fileExtension)"
        } else {
            filename = "artwork.\(fileExtension)"
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        // Convert to appropriate format
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw NSError(
                domain: "MetadataEditorViewModel",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]
            )
        }
        
        let imageData: Data?
        if fileExtension == "png" {
            imageData = bitmapRep.representation(using: .png, properties: [:])
        } else {
            imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
        
        guard let finalData = imageData else {
            throw NSError(
                domain: "MetadataEditorViewModel",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"]
            )
        }
        
        try finalData.write(to: fileURL)
        return fileURL
    }
    
    /// Import artwork from an image file
    func importArtwork(from url: URL) async {
        errorMessage = nil
        successMessage = nil
        
        guard let image = NSImage(contentsOf: url) else {
            errorMessage = "Invalid image file"
            return
        }
        
        metadata?.artwork = image
        successMessage = "Artwork imported successfully"
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            Task {
                try? await Task.sleep(for: .seconds(3))
                self.successMessage = nil
            }
        }
    }
    
    /// Remove artwork from metadata
    func removeArtwork() {
        metadata?.artwork = nil
        successMessage = "Artwork removed"
        
        // Clear success message after 3 seconds
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                self.successMessage = nil
            }
        }
    }
    
    // MARK: - Security-Scoped Resource Management
    
    /// Stop accessing the current security-scoped resource
    private func stopAccessingSecurityScopedResource() {
        if isAccessingSecurityScopedResource, let url = selectedFileURL {
            url.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
    }
}
