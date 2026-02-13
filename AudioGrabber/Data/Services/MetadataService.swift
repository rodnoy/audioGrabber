//
//  MetadataService.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import AVFoundation
import AppKit
import OSLog

/// Service for reading and writing audio file metadata using AVFoundation
final class MetadataService: MetadataServiceProtocol {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber", category: "MetadataService")
    
    // MARK: - MetadataServiceProtocol Implementation
    
    func readMetadata(from fileURL: URL) async throws -> AudioFileMetadata {
        logger.info("Reading metadata from: \(fileURL.path)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.error("File not found: \(fileURL.path)")
            throw AppError.fileSystemError(message: "File not found at path: \(fileURL.path)")
        }
        
        let asset = AVAsset(url: fileURL)
        
        // Load metadata asynchronously
        let metadata = try await asset.load(.metadata)
        let commonMetadata = try await asset.load(.commonMetadata)
        
        // Extract editable metadata
        let title = await extractString(for: .commonKeyTitle, from: commonMetadata)
        let artist = await extractString(for: .commonKeyArtist, from: commonMetadata)
        let album = await extractString(for: .commonKeyAlbumName, from: commonMetadata)
        let composer = await extractComposer(from: metadata)
        let genre = await extractString(for: .commonKeyType, from: commonMetadata)
        let comment = await extractString(for: .commonKeyDescription, from: commonMetadata)
        let lyrics = await extractLyrics(from: metadata)
        let artwork = await extractArtworkImage(from: commonMetadata)
        
        // Extract year from creation date
        let year = await extractYear(from: commonMetadata)
        
        // Extract track and disc numbers
        let (trackNumber, trackTotal) = await extractTrackInfo(from: metadata)
        let (discNumber, discTotal) = await extractDiscInfo(from: metadata)
        
        // Extract album artist
        let albumArtist = await extractAlbumArtist(from: metadata)
        
        // Extract technical information
        let duration = try? await asset.load(.duration).seconds
        let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64
        let fileFormat = fileURL.pathExtension.lowercased()
        
        // Extract audio track information
        let tracks = try await asset.load(.tracks)
        let audioTracks = tracks.filter { $0.mediaType == .audio }
        let audioTrack = audioTracks.first
        
        var bitrate: Int?
        var sampleRate: Int?
        var channels: Int?
        
        if let audioTrack = audioTrack {
            if let formatDescriptions = try? await audioTrack.load(.formatDescriptions),
               let formatDescription = formatDescriptions.first {
                let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
                if let asbd = audioStreamBasicDescription {
                    sampleRate = Int(asbd.pointee.mSampleRate)
                    channels = Int(asbd.pointee.mChannelsPerFrame)
                }
            }
            
            // Estimate bitrate
            if let duration = duration, duration > 0, let fileSize = fileSize {
                bitrate = Int((Double(fileSize) * 8) / duration)
            }
        }
        
        logger.info("Successfully read metadata from: \(fileURL.lastPathComponent)")
        
        return AudioFileMetadata(
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            composer: composer,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            trackTotal: trackTotal,
            discNumber: discNumber,
            discTotal: discTotal,
            comment: comment,
            lyrics: lyrics,
            artwork: artwork,
            duration: duration,
            bitrate: bitrate,
            sampleRate: sampleRate,
            channels: channels,
            fileFormat: fileFormat,
            fileSize: fileSize
        )
    }
    
    func writeMetadata(_ metadata: AudioFileMetadata, to fileURL: URL, outputURL: URL? = nil) async throws {
        let targetURL = outputURL ?? fileURL
        logger.info("Writing metadata from: \(fileURL.path) to: \(targetURL.path)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.error("File not found: \(fileURL.path)")
            throw AppError.fileSystemError(message: "File not found at path: \(fileURL.path)")
        }
        
        // Check if file format is supported for metadata writing
        let fileFormat = fileURL.pathExtension.lowercased()
        guard isSupportedForWriting(format: fileFormat) else {
            logger.error("Unsupported file format for metadata writing: \(fileFormat)")
            throw AppError.fileSystemError(message: "MP3 metadata editing is not supported. Please use M4A format instead.")
        }
        
        let asset = AVURLAsset(url: fileURL)
        
        // Create mutable metadata items
        var metadataItems: [AVMetadataItem] = []
        
        // Add common metadata
        if let title = metadata.title {
            metadataItems.append(createMetadataItem(for: .commonKeyTitle, value: title))
        }
        
        if let artist = metadata.artist {
            metadataItems.append(createMetadataItem(for: .commonKeyArtist, value: artist))
        }
        
        if let album = metadata.album {
            metadataItems.append(createMetadataItem(for: .commonKeyAlbumName, value: album))
        }
        
        if let composer = metadata.composer {
            metadataItems.append(createiTunesMetadataItem(key: "©wrt", value: composer))
        }
        
        if let genre = metadata.genre {
            metadataItems.append(createMetadataItem(for: .commonKeyType, value: genre))
        }
        
        if let comment = metadata.comment {
            metadataItems.append(createMetadataItem(for: .commonKeyDescription, value: comment))
        }
        
        if let year = metadata.year {
            let dateString = "\(year)-01-01T00:00:00Z"
            metadataItems.append(createMetadataItem(for: .commonKeyCreationDate, value: dateString))
        }
        
        if let artwork = metadata.artwork {
            if let artworkData = artwork.tiffRepresentation {
                metadataItems.append(createMetadataItem(for: .commonKeyArtwork, value: artworkData as NSData))
            }
        }
        
        // Add format-specific metadata for track/disc numbers and album artist
        if fileFormat == "m4a" || fileFormat == "m4p" || fileFormat == "m4b" {
            // iTunes metadata
            if let albumArtist = metadata.albumArtist {
                metadataItems.append(createiTunesMetadataItem(key: "aART", value: albumArtist))
            }
            
            if let trackNumber = metadata.trackNumber {
                let trackData = createiTunesTrackData(trackNumber: trackNumber, trackTotal: metadata.trackTotal)
                metadataItems.append(createiTunesMetadataItem(key: "trkn", value: trackData as NSData))
            }
            
            if let discNumber = metadata.discNumber {
                let discData = createiTunesDiscData(discNumber: discNumber, discTotal: metadata.discTotal)
                metadataItems.append(createiTunesMetadataItem(key: "disk", value: discData as NSData))
            }
            
            if let lyrics = metadata.lyrics {
                metadataItems.append(createiTunesMetadataItem(key: "©lyr", value: lyrics))
            }
        } else if fileFormat == "mp3" {
            // ID3 metadata
            if let albumArtist = metadata.albumArtist {
                metadataItems.append(createID3MetadataItem(key: "TPE2", value: albumArtist))
            }
            
            if let trackNumber = metadata.trackNumber {
                let trackString = metadata.trackTotal != nil ? "\(trackNumber)/\(metadata.trackTotal!)" : "\(trackNumber)"
                metadataItems.append(createID3MetadataItem(key: "TRCK", value: trackString))
            }
            
            if let discNumber = metadata.discNumber {
                let discString = metadata.discTotal != nil ? "\(discNumber)/\(metadata.discTotal!)" : "\(discNumber)"
                metadataItems.append(createID3MetadataItem(key: "TPOS", value: discString))
            }
            
            if let lyrics = metadata.lyrics {
                metadataItems.append(createID3MetadataItem(key: "USLT", value: lyrics))
            }
        }
        
        // Export with new metadata
        try await exportAsset(asset, with: metadataItems, to: fileURL, outputURL: targetURL)
        
        logger.info("Successfully wrote metadata to: \(targetURL.lastPathComponent)")
    }
    
    func extractArtwork(from fileURL: URL) async throws -> NSImage? {
        logger.info("Extracting artwork from: \(fileURL.path)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.error("File not found: \(fileURL.path)")
            throw AppError.fileSystemError(message: "File not found at path: \(fileURL.path)")
        }
        
        let asset = AVAsset(url: fileURL)
        let commonMetadata = try await asset.load(.commonMetadata)
        
        return await extractArtworkImage(from: commonMetadata)
    }
    
    func setArtwork(_ image: NSImage?, for fileURL: URL) async throws {
        logger.info("Setting artwork for: \(fileURL.path)")
        
        // Read existing metadata
        var metadata = try await readMetadata(from: fileURL)
        
        // Update artwork
        metadata.artwork = image
        
        // Write back (overwrite original file)
        try await writeMetadata(metadata, to: fileURL, outputURL: nil)
        
        logger.info("Successfully set artwork for: \(fileURL.lastPathComponent)")
    }
    
    // MARK: - Private Helper Methods
    
    private func extractString(for key: AVMetadataKey, from metadata: [AVMetadataItem]) async -> String? {
        for item in metadata where item.commonKey == key {
            if let value = try? await item.load(.stringValue) {
                return value
            }
        }
        return nil
    }
    
    private func extractComposer(from metadata: [AVMetadataItem]) async -> String? {
        // Try iTunes metadata first
        for item in metadata {
            let keySpace = item.keySpace
            if keySpace == .iTunes, let key = item.key as? String, key == "©wrt" {
                return try? await item.load(.stringValue)
            } else if keySpace == .id3, let key = item.key as? String, key == "TCOM" {
                return try? await item.load(.stringValue)
            }
        }
        return nil
    }
    
    private func extractYear(from metadata: [AVMetadataItem]) async -> Int? {
        for item in metadata where item.commonKey == .commonKeyCreationDate {
            if let dateString = try? await item.load(.stringValue) {
                // Try to extract year from various date formats
                let yearPattern = #"(\d{4})"#
                if let regex = try? NSRegularExpression(pattern: yearPattern),
                   let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
                   let range = Range(match.range(at: 1), in: dateString) {
                    return Int(dateString[range])
                }
            }
        }
        return nil
    }
    
    private func extractLyrics(from metadata: [AVMetadataItem]) async -> String? {
        // Try different metadata formats for lyrics
        for item in metadata {
            let keySpace = item.keySpace
            
            if keySpace == .iTunes, let key = item.key as? String, key == "©lyr" {
                return try? await item.load(.stringValue)
            } else if keySpace == .id3, let key = item.key as? String, key == "USLT" {
                return try? await item.load(.stringValue)
            }
        }
        return nil
    }
    
    private func extractArtworkImage(from metadata: [AVMetadataItem]) async -> NSImage? {
        for item in metadata where item.commonKey == .commonKeyArtwork {
            if let data = try? await item.load(.dataValue), let image = NSImage(data: data) {
                return image
            }
        }
        return nil
    }
    
    private func extractTrackInfo(from metadata: [AVMetadataItem]) async -> (trackNumber: Int?, trackTotal: Int?) {
        for item in metadata {
            let keySpace = item.keySpace
            
            if keySpace == .iTunes, let key = item.key as? String, key == "trkn" {
                if let data = try? await item.load(.dataValue) {
                    return parseiTunesTrackData(data)
                }
            } else if keySpace == .id3, let key = item.key as? String, key == "TRCK" {
                if let value = try? await item.load(.stringValue) {
                    return parseTrackString(value)
                }
            }
        }
        return (nil, nil)
    }
    
    private func extractDiscInfo(from metadata: [AVMetadataItem]) async -> (discNumber: Int?, discTotal: Int?) {
        for item in metadata {
            let keySpace = item.keySpace
            
            if keySpace == .iTunes, let key = item.key as? String, key == "disk" {
                if let data = try? await item.load(.dataValue) {
                    return parseiTunesDiscData(data)
                }
            } else if keySpace == .id3, let key = item.key as? String, key == "TPOS" {
                if let value = try? await item.load(.stringValue) {
                    return parseTrackString(value)
                }
            }
        }
        return (nil, nil)
    }
    
    private func extractAlbumArtist(from metadata: [AVMetadataItem]) async -> String? {
        for item in metadata {
            let keySpace = item.keySpace
            
            if keySpace == .iTunes, let key = item.key as? String, key == "aART" {
                return try? await item.load(.stringValue)
            } else if keySpace == .id3, let key = item.key as? String, key == "TPE2" {
                return try? await item.load(.stringValue)
            }
        }
        return nil
    }
    
    private func parseTrackString(_ value: String) -> (Int?, Int?) {
        let components = value.split(separator: "/")
        let trackNumber = components.first.flatMap { Int($0) }
        let trackTotal = components.count > 1 ? Int(components[1]) : nil
        return (trackNumber, trackTotal)
    }
    
    private func parseiTunesTrackData(_ data: Data) -> (Int?, Int?) {
        guard data.count >= 8 else { return (nil, nil) }
        let trackNumber = Int(data[3])
        let trackTotal = data.count > 4 ? Int(data[5]) : nil
        return (trackNumber > 0 ? trackNumber : nil, trackTotal)
    }
    
    private func parseiTunesDiscData(_ data: Data) -> (Int?, Int?) {
        guard data.count >= 6 else { return (nil, nil) }
        let discNumber = Int(data[3])
        let discTotal = data.count > 4 ? Int(data[5]) : nil
        return (discNumber > 0 ? discNumber : nil, discTotal)
    }
    
    private func createMetadataItem(for key: AVMetadataKey, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .common
        item.key = key.rawValue as NSString
        item.value = value as? NSCopying & NSObjectProtocol
        return item
    }
    
    private func createiTunesMetadataItem(key: String, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .iTunes
        item.key = key as NSString
        item.value = value as? NSCopying & NSObjectProtocol
        return item
    }
    
    private func createID3MetadataItem(key: String, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .id3
        item.key = key as NSString
        item.value = value as? NSCopying & NSObjectProtocol
        return item
    }
    
    private func createiTunesTrackData(trackNumber: Int, trackTotal: Int?) -> Data {
        var data = Data(count: 8)
        data[2] = 0
        data[3] = UInt8(trackNumber)
        if let total = trackTotal {
            data[5] = UInt8(total)
        }
        return data
    }
    
    private func createiTunesDiscData(discNumber: Int, discTotal: Int?) -> Data {
        var data = Data(count: 6)
        data[2] = 0
        data[3] = UInt8(discNumber)
        if let total = discTotal {
            data[5] = UInt8(total)
        }
        return data
    }
    
    private func exportAsset(_ asset: AVAsset, with metadata: [AVMetadataItem], to sourceURL: URL, outputURL: URL) async throws {
        let fileFormat = sourceURL.pathExtension.lowercased()
        
        // Validate format is supported for export
        guard isSupportedForWriting(format: fileFormat) else {
            logger.error("Unsupported file format for export: \(fileFormat)")
            throw AppError.fileSystemError(message: "Cannot export \(fileFormat.uppercased()) files. Only M4A format is supported for metadata editing.")
        }
        
        // Create temporary output URL in the same directory as the output file
        let tempURL = outputURL.deletingLastPathComponent()
            .appendingPathComponent("temp_\(UUID().uuidString)")
            .appendingPathExtension(outputURL.pathExtension)
        
        logger.info("Creating temporary file at: \(tempURL.path)")
        
        // Use AppleM4A preset for M4A files
        let presetName = AVAssetExportPresetAppleM4A
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            logger.error("Failed to create export session for preset: \(presetName)")
            throw AppError.fileSystemError(message: "Failed to create export session. The file format may not be supported.")
        }
        
        // Configure export session
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .m4a
        exportSession.metadata = metadata
        
        logger.info("Starting export with preset: \(presetName)")
        
        // Perform export
        await exportSession.export()
        
        // Check export status
        guard exportSession.status == .completed else {
            // Clean up temp file if it was created
            try? FileManager.default.removeItem(at: tempURL)
            
            if let error = exportSession.error {
                logger.error("Export failed with error: \(error.localizedDescription)")
                throw AppError.fileSystemError(message: "Failed to save metadata: \(error.localizedDescription)")
            } else {
                logger.error("Export failed with status: \(exportSession.status.rawValue)")
                throw AppError.fileSystemError(message: "Failed to save metadata: Export status \(exportSession.status.rawValue)")
            }
        }
        
        logger.info("Export completed successfully, moving to output location")
        
        // Move temp file to output location
        do {
            // If output file already exists, remove it first
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            // Move temp file to output location
            try FileManager.default.moveItem(at: tempURL, to: outputURL)
            logger.info("Successfully saved file to: \(outputURL.path)")
        } catch {
            // Clean up temp file on failure
            try? FileManager.default.removeItem(at: tempURL)
            logger.error("Failed to save file: \(error.localizedDescription)")
            throw AppError.fileSystemError(message: "Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    /// Checks if the given file format is supported for metadata writing
    private func isSupportedForWriting(format: String) -> Bool {
        let supportedFormats = ["m4a", "m4p", "m4b"]
        return supportedFormats.contains(format.lowercased())
    }
}
