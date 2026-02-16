//
//  RenameItem.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-13.
//

import Foundation
import AppKit

/// Status of a file rename operation
enum RenameStatus: Equatable {
    /// File is waiting to be renamed
    case pending
    
    /// File has no title in metadata (cannot be renamed)
    case noTitle
    
    /// File was successfully renamed
    case renamed
    
    /// File rename failed with an error message
    case failed(String)
    
    /// File was skipped by user
    case skipped
}

/// Represents a file that can be renamed based on its metadata
struct RenameItem: Identifiable, Equatable {
    /// Unique identifier for the item
    let id: UUID
    
    /// Original file URL
    let originalURL: URL
    
    /// Original file name (without extension)
    let originalName: String
    
    /// File extension (e.g., "mp3", "m4a")
    let fileExtension: String
    
    /// New name based on metadata title (nil if no title available)
    var newName: String?
    
    /// Whether the item is selected for batch operations
    var isSelected: Bool
    
    /// Current status of the rename operation
    var status: RenameStatus
    
    /// Whether the file can be renamed (has a new name and is pending)
    var canBeRenamed: Bool {
        newName != nil && status == .pending
    }
    
    /// Display name for the new file (includes extension)
    var displayNewName: String {
        if let name = newName {
            return name + "." + fileExtension
        }
        return "—"
    }
    
    /// Full URL for the renamed file (nil if no new name)
    var fullNewURL: URL? {
        guard let name = newName else { return nil }
        return originalURL.deletingLastPathComponent()
            .appendingPathComponent(name)
            .appendingPathExtension(fileExtension)
    }
}
