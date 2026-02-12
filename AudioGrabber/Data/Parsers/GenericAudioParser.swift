//
//  GenericAudioParser.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import OSLog

/// Universal parser for extracting direct audio file links from any website
@MainActor
final class GenericAudioParser: MediaParserProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber.app", category: "GenericAudioParser")
    
    let identifier: String = "generic"
    let name: String = "Generic Audio Parser"
    let supportedDomains: [String] = [] // Universal parser
    let priority: Int = 0 // Base priority
    
    // MARK: - Audio File Patterns
    
    /// Regex pattern for detecting direct audio file URLs
    /// Matches: https://example.com/file.mp3, http://site.com/audio.m4a, etc.
    private let audioURLPattern = #"https?://[^"'\s]+\.(mp3|m4a|wav|ogg|flac|aac|opus)"#
    
    // MARK: - MediaParserProtocol Implementation
    
    func canParse(url: URL) -> Bool {
        // Universal parser can attempt to parse any URL
        return true
    }
    
    func parse(html: String, sourceURL: URL) async throws -> ParserResult {
        logger.info("Starting generic audio parsing for URL: \(sourceURL.absoluteString)")
        
        guard let regex = try? NSRegularExpression(pattern: audioURLPattern, options: .caseInsensitive) else {
            logger.error("Failed to create regex pattern")
            throw AppError.parsingError(message: "Invalid regex pattern")
        }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        guard !matches.isEmpty else {
            logger.warning("No audio files found in HTML content")
            throw AppError.parsingError(message: "No audio files found on the page")
        }
        
        logger.info("Found \(matches.count) potential audio file(s)")
        
        var mediaItems: [MediaItem] = []
        var seenURLs = Set<String>()
        
        for match in matches {
            let urlString = nsString.substring(with: match.range)
            
            // Avoid duplicates
            guard !seenURLs.contains(urlString) else { continue }
            seenURLs.insert(urlString)
            
            guard let audioURL = URL(string: urlString) else {
                logger.warning("Invalid URL found: \(urlString)")
                continue
            }
            
            // Extract filename from URL
            let filename = extractFilename(from: audioURL)
            let fileExtension = audioURL.pathExtension.lowercased()
            
            // Determine format
            let format = AudioFormat(rawValue: fileExtension) ?? .mp3
            
            let mediaItem = MediaItem(
                url: audioURL,
                fileName: audioURL.lastPathComponent,
                displayName: filename,
                fileExtension: format,
                fileSize: nil,
                metadata: MediaMetadata(
                    title: filename,
                    artist: nil,
                    album: nil,
                    duration: nil
                )
            )
            
            mediaItems.append(mediaItem)
            logger.debug("Extracted audio: \(filename) (\(format.rawValue))")
        }
        
        guard !mediaItems.isEmpty else {
            logger.error("No valid audio URLs could be extracted")
            throw AppError.parsingError(message: "No valid audio URLs found")
        }
        
        logger.info("Successfully parsed \(mediaItems.count) audio file(s)")
        
        return ParserResult(
            items: mediaItems,
            parserIdentifier: identifier,
            sourceURL: sourceURL
        )
    }
    
    // MARK: - Helper Methods
    
    /// Extracts a clean filename from the audio URL
    /// - Parameter url: The audio file URL
    /// - Returns: A cleaned filename without extension
    private func extractFilename(from url: URL) -> String {
        let pathComponent = url.lastPathComponent
        
        // Remove extension
        let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        
        // Decode URL encoding
        let decoded = filenameWithoutExtension.removingPercentEncoding ?? filenameWithoutExtension
        
        // Clean up common URL artifacts
        let cleaned = decoded
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? pathComponent : cleaned
    }
}
