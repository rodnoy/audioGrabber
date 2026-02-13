//
//  SwiftTaggerService.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-13.
//

import AppKit
import AVFoundation
import Foundation
import OSLog
import SwiftTagger
import SwiftConvenienceExtensions

/// Service for reading and writing audio file metadata using SwiftTagger library
/// Supports MP3 (ID3 tags) and M4A (MP4 atoms) formats
final class SwiftTaggerService: MetadataServiceProtocol {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber", category: "SwiftTaggerService")
    private let fileManager = FileManager.default
    
    // MARK: - MetadataServiceProtocol Implementation
    
    func readMetadata(from fileURL: URL) async throws -> AudioFileMetadata {
        logger.info("Reading metadata from: \(fileURL.path)")
        logger.info("File extension: \(fileURL.pathExtension)")
        
        do {
            let audioFile = try AudioFile(location: fileURL)
            
            // Extract year from recordingDateTime
            let year: Int? = if let recordingDate = audioFile.recordingDateTime {
                Calendar.current.component(.year, from: recordingDate)
            } else {
                nil
            }
            
            // Get technical information from file attributes
            let fileAttributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = fileAttributes?[.size] as? Int64
            
            // Try to get artwork from SwiftTagger first
            var artwork = audioFile.coverArt
            logger.info("Artwork from SwiftTagger: \(artwork == nil ? "nil" : "present")")
            if let artworkImage = artwork {
                logger.info("Artwork size: \(artworkImage.size.width)x\(artworkImage.size.height)")
            }
            
            // Fallback to AVFoundation for MP3 files if SwiftTagger returns nil
            if artwork == nil && fileURL.pathExtension.lowercased() == "mp3" {
                logger.info("SwiftTagger returned nil for MP3 artwork, trying AVFoundation fallback...")
                artwork = await extractArtworkWithAVFoundation(from: fileURL)
                if artwork != nil {
                    logger.info("Successfully extracted artwork using AVFoundation fallback")
                } else {
                    logger.info("AVFoundation fallback also returned nil")
                }
            }
            
            // Create metadata object
            let metadata = AudioFileMetadata(
                title: audioFile.title,
                artist: audioFile.artist,
                album: audioFile.album,
                albumArtist: audioFile.albumArtist,
                composer: audioFile.composer,
                genre: audioFile.genreCustom,
                year: year,
                trackNumber: audioFile.trackNumber.index,
                trackTotal: audioFile.trackNumber.total,
                discNumber: audioFile.discNumber.index,
                discTotal: audioFile.discNumber.total,
                comment: audioFile.comments,
                lyrics: nil, // SwiftTagger doesn't expose lyrics in a simple property
                artwork: artwork,
                duration: nil, // Technical info not available from SwiftTagger
                bitrate: nil,
                sampleRate: nil,
                channels: nil,
                fileFormat: fileURL.pathExtension.lowercased(),
                fileSize: fileSize
            )
            
            logger.info("Successfully read metadata from: \(fileURL.path)")
            return metadata
            
        } catch {
            logger.error("Failed to read metadata from \(fileURL.path): \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to read metadata: \(error.localizedDescription)")
        }
    }
    
    func writeMetadata(_ metadata: AudioFileMetadata, to fileURL: URL, outputURL: URL?) async throws {
        let targetURL = outputURL ?? fileURL
        logger.info("Writing metadata to: \(targetURL.path)")
        logger.info("Source file extension: \(fileURL.pathExtension)")
        logger.info("Target file extension: \(targetURL.pathExtension)")
        
        do {
            var audioFile = try AudioFile(location: fileURL)
            
            // Map AudioFileMetadata to SwiftTagger properties
            audioFile.title = metadata.title
            audioFile.artist = metadata.artist
            audioFile.album = metadata.album
            audioFile.albumArtist = metadata.albumArtist
            audioFile.composer = metadata.composer
            audioFile.genreCustom = metadata.genre
            audioFile.comments = metadata.comment
            
            // Set track numbers using IntIndex
            audioFile.trackNumber = IntIndex(
                index: metadata.trackNumber ?? 0,
                total: metadata.trackTotal
            )
            
            // Set disc numbers using IntIndex
            audioFile.discNumber = IntIndex(
                index: metadata.discNumber ?? 0,
                total: metadata.discTotal
            )
            
            // Set year as recordingDateTime
            if let year = metadata.year {
                var components = DateComponents()
                components.year = year
                components.month = 1
                components.day = 1
                if let date = Calendar.current.date(from: components) {
                    audioFile.recordingDateTime = date
                }
            }
            
            // Handle artwork separately
            if let artwork = metadata.artwork {
                try await setArtworkInternal(&audioFile, image: artwork)
            } else {
                try audioFile.removeCoverArt()
            }
            
            // Write to temp file first to preserve original extension
            let originalExtension = targetURL.pathExtension
            logger.info("Using extension for temp file: \(originalExtension)")
            
            let tempURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(originalExtension)
            
            logger.info("Temp file URL: \(tempURL.path)")
            logger.info("Temp file extension: \(tempURL.pathExtension)")
            
            try audioFile.write(outputLocation: tempURL)
            
            logger.info("File written to temp location, now replacing...")
            
            // Replace original file with temp file
            _ = try fileManager.replaceItemAt(targetURL, withItemAt: tempURL)
            
            logger.info("Successfully wrote metadata to: \(targetURL.path)")
            logger.info("Final file extension: \(targetURL.pathExtension)")
            
        } catch {
            logger.error("Failed to write metadata to \(targetURL.path): \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to write metadata: \(error.localizedDescription)")
        }
    }
    
    func extractArtwork(from fileURL: URL) async throws -> NSImage? {
        logger.info("Extracting artwork from: \(fileURL.path)")
        logger.info("File extension: \(fileURL.pathExtension)")
        
        do {
            let audioFile = try AudioFile(location: fileURL)
            var artwork = audioFile.coverArt
            
            logger.info("SwiftTagger coverArt type: \(type(of: artwork))")
            logger.info("SwiftTagger coverArt is nil: \(artwork == nil)")
            
            // Fallback to AVFoundation for MP3 files if SwiftTagger returns nil
            if artwork == nil && fileURL.pathExtension.lowercased() == "mp3" {
                logger.info("SwiftTagger returned nil for MP3 artwork, trying AVFoundation fallback...")
                artwork = await extractArtworkWithAVFoundation(from: fileURL)
                if artwork != nil {
                    logger.info("Successfully extracted artwork using AVFoundation fallback")
                } else {
                    logger.info("AVFoundation fallback also returned nil")
                }
            }
            
            if artwork != nil {
                logger.info("Successfully extracted artwork from: \(fileURL.path)")
                logger.info("Artwork size: \(artwork!.size.width)x\(artwork!.size.height)")
            } else {
                logger.info("No artwork found in: \(fileURL.path)")
            }
            
            return artwork
            
        } catch {
            logger.error("Failed to extract artwork from \(fileURL.path): \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to extract artwork: \(error.localizedDescription)")
        }
    }
    
    func setArtwork(_ image: NSImage?, for fileURL: URL) async throws {
        logger.info("Setting artwork for: \(fileURL.path)")
        
        do {
            var audioFile = try AudioFile(location: fileURL)
            
            if let image = image {
                try await setArtworkInternal(&audioFile, image: image)
            } else {
                try audioFile.removeCoverArt()
            }
            
            // Write to temp file first to preserve original extension
            let originalExtension = fileURL.pathExtension
            let tempURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(originalExtension)
            
            try audioFile.write(outputLocation: tempURL)
            
            // Replace original file with temp file
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: tempURL)
            
            logger.info("Successfully set artwork for: \(fileURL.path)")
            
        } catch {
            logger.error("Failed to set artwork for \(fileURL.path): \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to set artwork: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sets artwork on an AudioFile by saving the image to a temporary file
    /// - Parameters:
    ///   - audioFile: The audio file to modify (inout)
    ///   - image: The NSImage to set as artwork
    private func setArtworkInternal(_ audioFile: inout AudioFile, image: NSImage) async throws {
        // SwiftTagger requires a file URL to set artwork, so we need to save the image temporarily
        let tempDir = fileManager.temporaryDirectory
        let tempImageURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        // Convert NSImage to JPEG data and save to temp file
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw AppError.fileSystemError(message: "Failed to convert image to JPEG format")
        }
        
        try jpegData.write(to: tempImageURL)
        
        defer {
            // Clean up temporary file
            try? fileManager.removeItem(at: tempImageURL)
        }
        
        // Set the artwork using the temporary file
        try audioFile.setCoverArt(imageLocation: tempImageURL)
    }
    
    /// Extracts artwork using AVFoundation as a fallback for MP3 files
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: The extracted NSImage, or nil if no artwork is found
    private func extractArtworkWithAVFoundation(from fileURL: URL) async -> NSImage? {
        logger.info("Using AVFoundation fallback to extract artwork from: \(fileURL.path)")
        
        let asset = AVAsset(url: fileURL)
        
        do {
            let commonMetadata = try await asset.load(.commonMetadata)
            
            for item in commonMetadata where item.commonKey == .commonKeyArtwork {
                if let data = try? await item.load(.dataValue), let image = NSImage(data: data) {
                    logger.info("AVFoundation successfully extracted artwork")
                    return image
                }
            }
            
            logger.info("AVFoundation found no artwork in metadata")
            return nil
            
        } catch {
            logger.error("AVFoundation failed to load metadata: \(error.localizedDescription)")
            return nil
        }
    }
}
