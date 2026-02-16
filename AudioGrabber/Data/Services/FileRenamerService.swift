//
//  FileRenamerService.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-13.
//

import Foundation
import AppKit
import OSLog

/// Service for renaming audio files based on their metadata
actor FileRenamerService {
    // MARK: - Properties
    
    private let metadataService: MetadataServiceProtocol
    private let logger = Logger(subsystem: "AudioGrabber", category: "FileRenamerService")
    private let fileManager = FileManager.default
    
    /// Supported audio file extensions
    private let supportedExtensions = ["mp3", "m4a", "mp4", "m4b", "aac", "wav", "flac", "aiff"]
    
    // MARK: - Initialization
    
    init(metadataService: MetadataServiceProtocol = SwiftTaggerService()) {
        self.metadataService = metadataService
    }
    
    // MARK: - Public Methods
    
    /// Scans a folder and returns a list of audio files that can be renamed
    /// - Parameter url: URL of the folder to scan
    /// - Returns: Array of RenameItem objects representing files in the folder
    /// - Throws: AppError if scanning fails
    func scanFolder(at url: URL) async throws -> [RenameItem] {
        logger.info("Scanning folder: \(url.path)")
        
        guard fileManager.fileExists(atPath: url.path) else {
            logger.error("Folder does not exist: \(url.path)")
            throw AppError.fileSystemError(message: "Folder does not exist")
        }
        
        do {
            // Get directory contents
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            logger.info("Found \(contents.count) items in folder")
            
            // Filter audio files
            let audioFiles = contents.filter { isAudioFile($0) }
            logger.info("Found \(audioFiles.count) audio files")
            
            // Process each audio file
            var renameItems: [RenameItem] = []
            
            for fileURL in audioFiles {
                let item = await createRenameItem(from: fileURL)
                renameItems.append(item)
            }
            
            logger.info("Created \(renameItems.count) rename items")
            return renameItems
            
        } catch {
            logger.error("Failed to scan folder: \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to scan folder: \(error.localizedDescription)")
        }
    }
    
    /// Renames a single file based on its metadata
    /// - Parameter item: The RenameItem to process
    /// - Returns: Updated RenameItem with new status
    /// - Throws: AppError if renaming fails
    func renameFile(_ item: RenameItem) async throws -> RenameItem {
        logger.info("Renaming file: \(item.originalURL.path)")
        
        // Check if file can be renamed
        guard item.canBeRenamed else {
            logger.warning("File cannot be renamed: \(item.originalURL.path)")
            throw AppError.fileSystemError(message: "File cannot be renamed")
        }
        
        guard let newName = item.newName else {
            logger.error("No new name available for file: \(item.originalURL.path)")
            throw AppError.fileSystemError(message: "No new name available")
        }
        
        do {
            // Sanitize the new name
            let sanitizedName = sanitizeFileName(newName)
            
            // Create new URL
            let newURL = item.originalURL.deletingLastPathComponent()
                .appendingPathComponent(sanitizedName)
                .appendingPathExtension(item.fileExtension)
            
            // Check if file already exists and get unique name if needed
            let finalURL = getUniqueFileName(for: newURL)
            
            // Perform the rename
            try fileManager.moveItem(at: item.originalURL, to: finalURL)
            
            logger.info("Successfully renamed file to: \(finalURL.path)")
            
            // Return updated item
            var updatedItem = item
            updatedItem.status = .renamed
            return updatedItem
            
        } catch {
            logger.error("Failed to rename file: \(error.localizedDescription)")
            
            var updatedItem = item
            updatedItem.status = .failed(error.localizedDescription)
            return updatedItem
        }
    }
    
    /// Renames multiple files in batch
    /// - Parameter items: Array of RenameItem objects to process
    /// - Returns: Array of updated RenameItem objects with their new statuses
    func renameFiles(_ items: [RenameItem]) async -> [RenameItem] {
        logger.info("Batch renaming \(items.count) files")
        
        var updatedItems: [RenameItem] = []
        
        for item in items {
            // Only process selected items that can be renamed
            guard item.isSelected && item.canBeRenamed else {
                var skippedItem = item
                if !item.isSelected {
                    skippedItem.status = .skipped
                }
                updatedItems.append(skippedItem)
                continue
            }
            
            do {
                let updatedItem = try await renameFile(item)
                updatedItems.append(updatedItem)
            } catch {
                logger.error("Failed to rename file in batch: \(error.localizedDescription)")
                var failedItem = item
                failedItem.status = .failed(error.localizedDescription)
                updatedItems.append(failedItem)
            }
        }
        
        let successCount = updatedItems.filter { $0.status == .renamed }.count
        logger.info("Batch rename completed: \(successCount)/\(items.count) successful")
        
        return updatedItems
    }
    
    // MARK: - Private Methods
    
    /// Creates a RenameItem from a file URL by reading its metadata
    /// - Parameter fileURL: URL of the audio file
    /// - Returns: RenameItem with metadata-based new name
    private func createRenameItem(from fileURL: URL) async -> RenameItem {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()
        
        // Try to read metadata
        var newName: String?
        var status: RenameStatus = .pending
        
        do {
            let metadata = try await metadataService.readMetadata(from: fileURL)
            
            if let title = metadata.title, !title.isEmpty {
                newName = title
                status = .pending
            } else {
                newName = nil
                status = .noTitle
            }
            
        } catch {
            logger.error("Failed to read metadata for \(fileURL.path): \(error.localizedDescription)")
            newName = nil
            status = .noTitle
        }
        
        return RenameItem(
            id: UUID(),
            originalURL: fileURL,
            originalName: originalName,
            fileExtension: fileExtension,
            newName: newName,
            isSelected: true, // Selected by default
            status: status
        )
    }
    
    /// Checks if a file is an audio file based on its extension
    /// - Parameter url: URL of the file to check
    /// - Returns: true if the file is an audio file
    private func isAudioFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    /// Sanitizes a file name by removing invalid characters
    /// - Parameter name: Original file name
    /// - Returns: Sanitized file name safe for file system
    private func sanitizeFileName(_ name: String) -> String {
        // Characters not allowed in file names: / \ : * ? " < > |
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        
        // Replace invalid characters with underscore
        let components = name.components(separatedBy: invalidCharacters)
        let sanitized = components.joined(separator: "_")
        
        // Trim whitespace and dots from edges
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        
        // Ensure the name is not empty
        return trimmed.isEmpty ? "Untitled" : trimmed
    }
    
    /// Gets a unique file name by adding a suffix if the file already exists
    /// - Parameter url: Desired file URL
    /// - Returns: Unique file URL (may be the same as input if no conflict)
    private func getUniqueFileName(for url: URL) -> URL {
        var finalURL = url
        var counter = 1
        
        // Keep incrementing counter until we find a unique name
        while fileManager.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let directory = url.deletingLastPathComponent()
            let pathExtension = url.pathExtension
            
            let newName = "\(nameWithoutExtension) (\(counter))"
            finalURL = directory
                .appendingPathComponent(newName)
                .appendingPathExtension(pathExtension)
            
            counter += 1
            
            // Safety check to prevent infinite loop
            if counter > 1000 {
                logger.error("Too many file name conflicts for: \(url.path)")
                break
            }
        }
        
        if counter > 1 {
            logger.info("File exists, using unique name: \(finalURL.lastPathComponent)")
        }
        
        return finalURL
    }
}
