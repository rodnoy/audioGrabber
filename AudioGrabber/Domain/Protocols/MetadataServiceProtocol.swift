//
//  MetadataServiceProtocol.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import AppKit

/// Protocol defining metadata operations for audio files
protocol MetadataServiceProtocol {
    /// Reads metadata from an audio file
    /// - Parameter fileURL: URL of the audio file
    /// - Returns: Audio file metadata
    /// - Throws: AppError if reading fails
    func readMetadata(from fileURL: URL) async throws -> AudioFileMetadata
    
    /// Writes metadata to an audio file
    /// - Parameters:
    ///   - metadata: Metadata to write
    ///   - fileURL: URL of the source audio file
    ///   - outputURL: Optional URL for the output file. If nil, overwrites the source file
    /// - Throws: AppError if writing fails
    func writeMetadata(_ metadata: AudioFileMetadata, to fileURL: URL, outputURL: URL?) async throws
    
    /// Extracts artwork from an audio file
    /// - Parameter fileURL: URL of the audio file
    /// - Returns: Album artwork image, or nil if not found
    /// - Throws: AppError if extraction fails
    func extractArtwork(from fileURL: URL) async throws -> NSImage?
    
    /// Sets artwork for an audio file
    /// - Parameters:
    ///   - image: Artwork image to set, or nil to remove
    ///   - fileURL: URL of the audio file
    /// - Throws: AppError if setting artwork fails
    func setArtwork(_ image: NSImage?, for fileURL: URL) async throws
}
