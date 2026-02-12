//
//  JSONMetadataParser.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import OSLog

/// Parser for extracting metadata from JSON embedded in HTML
/// Enriches audio file data with title, artist, and other metadata
@MainActor
final class JSONMetadataParser: MediaParserProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber.app", category: "JSONMetadataParser")
    private let genericParser = GenericAudioParser()
    
    let identifier: String = "json-metadata"
    let name: String = "JSON Metadata Parser"
    let supportedDomains: [String] = [] // Universal parser
    let priority: Int = 10 // Higher priority than generic parser
    
    // MARK: - JSON Patterns
    
    /// Regex patterns for extracting metadata from JSON
    private let namePattern = #""name"\s*:\s*"([^"]+)""#
    private let titlePattern = #""title"\s*:\s*"([^"]+)""#
    private let urlPattern = #""url"\s*:\s*"([^"]+)""#
    private let artistPattern = #""artist"\s*:\s*"([^"]+)""#
    private let albumPattern = #""album"\s*:\s*"([^"]+)""#
    private let durationPattern = #""duration"\s*:\s*"?([^",}]+)"?"#
    private let imagePattern = #""image"\s*:\s*"([^"]+)""#
    
    // MARK: - MediaParserProtocol Implementation
    
    func canParse(url: URL) -> Bool {
        // Universal parser can attempt to parse any URL
        return true
    }
    
    func parse(html: String, sourceURL: URL) async throws -> ParserResult {
        logger.info("Starting JSON metadata parsing for URL: \(sourceURL.absoluteString)")
        
        // First, use generic parser to find audio files
        let genericResult = try await genericParser.parse(html: html, sourceURL: sourceURL)
        
        // Extract metadata from JSON in HTML
        let metadata = extractMetadata(from: html)
        
        // Enrich media items with metadata
        let enrichedItems = enrichMediaItems(genericResult.items, with: metadata, sourceURL: sourceURL)
        
        logger.info("Successfully enriched \(enrichedItems.count) media item(s) with JSON metadata")
        
        return ParserResult(
            items: enrichedItems,
            parserIdentifier: identifier,
            sourceURL: sourceURL
        )
    }
    
    // MARK: - Metadata Extraction
    
    /// Extracts metadata from HTML content containing JSON
    /// - Parameter htmlContent: The HTML content to parse
    /// - Returns: Dictionary of extracted metadata
    private func extractMetadata(from htmlContent: String) -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Extract name/title
        if let name = extractFirstMatch(pattern: namePattern, from: htmlContent) {
            metadata["name"] = name
            logger.debug("Extracted name: \(name)")
        }
        
        if let title = extractFirstMatch(pattern: titlePattern, from: htmlContent) {
            metadata["title"] = title
            logger.debug("Extracted title: \(title)")
        }
        
        // Extract artist
        if let artist = extractFirstMatch(pattern: artistPattern, from: htmlContent) {
            metadata["artist"] = artist
            logger.debug("Extracted artist: \(artist)")
        }
        
        // Extract album
        if let album = extractFirstMatch(pattern: albumPattern, from: htmlContent) {
            metadata["album"] = album
            logger.debug("Extracted album: \(album)")
        }
        
        // Extract duration
        if let duration = extractFirstMatch(pattern: durationPattern, from: htmlContent) {
            metadata["duration"] = duration
            logger.debug("Extracted duration: \(duration)")
        }
        
        // Extract image/cover art
        if let image = extractFirstMatch(pattern: imagePattern, from: htmlContent) {
            metadata["image"] = image
            logger.debug("Extracted image URL: \(image)")
        }
        
        // Extract URL (for additional context)
        if let urlString = extractFirstMatch(pattern: urlPattern, from: htmlContent) {
            metadata["url"] = urlString
            logger.debug("Extracted URL: \(urlString)")
        }
        
        return metadata
    }
    
    /// Extracts the first match for a given regex pattern
    /// - Parameters:
    ///   - pattern: The regex pattern to match
    ///   - content: The content to search
    /// - Returns: The first captured group if found
    private func extractFirstMatch(pattern: String, from content: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let nsString = content as NSString
        guard let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: nsString.length)),
              match.numberOfRanges > 1 else {
            return nil
        }
        
        let capturedRange = match.range(at: 1)
        let captured = nsString.substring(with: capturedRange)
        
        // Decode HTML entities and clean up
        return cleanMetadataValue(captured)
    }
    
    /// Cleans metadata values by decoding HTML entities and trimming
    /// - Parameter value: The raw metadata value
    /// - Returns: Cleaned metadata value
    private func cleanMetadataValue(_ value: String) -> String {
        var cleaned = value
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "\\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Decode common HTML entities
        cleaned = cleaned
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        
        return cleaned
    }
    
    // MARK: - Media Item Enrichment
    
    /// Enriches media items with extracted metadata
    /// - Parameters:
    ///   - items: Original media items from generic parser
    ///   - metadata: Extracted metadata dictionary
    ///   - sourceURL: The source URL for context
    /// - Returns: Enriched media items
    private func enrichMediaItems(_ items: [MediaItem], with metadata: [String: String], sourceURL: URL) -> [MediaItem] {
        items.map { item in
            // Determine best title
            let title = metadata["title"] ?? metadata["name"] ?? item.displayName
            
            // Parse duration if available
            let duration = parseDuration(metadata["duration"])
            
            // Create enriched metadata
            let enrichedMetadata = MediaMetadata(
                title: title,
                artist: metadata["artist"],
                album: metadata["album"],
                duration: duration ?? item.metadata?.duration
            )
            
            return MediaItem(
                url: item.url,
                fileName: item.fileName,
                displayName: title,
                fileExtension: item.fileExtension,
                fileSize: item.fileSize,
                metadata: enrichedMetadata
            )
        }
    }
    
    /// Parses duration string to TimeInterval
    /// - Parameter durationString: Duration in various formats (ISO 8601, seconds, etc.)
    /// - Returns: TimeInterval if parsing succeeds
    private func parseDuration(_ durationString: String?) -> TimeInterval? {
        guard let durationString = durationString else { return nil }
        
        // Try parsing as seconds (numeric)
        if let seconds = Double(durationString) {
            return seconds
        }
        
        // Try parsing ISO 8601 duration (PT1H2M3S)
        if durationString.hasPrefix("PT") {
            return parseISO8601Duration(durationString)
        }
        
        return nil
    }
    
    /// Parses ISO 8601 duration format (e.g., PT1H2M3S)
    /// - Parameter iso8601: ISO 8601 duration string
    /// - Returns: TimeInterval if parsing succeeds
    private func parseISO8601Duration(_ iso8601: String) -> TimeInterval? {
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: iso8601, range: NSRange(location: 0, length: iso8601.count)) else {
            return nil
        }
        
        let nsString = iso8601 as NSString
        var totalSeconds: TimeInterval = 0
        
        // Hours
        if match.range(at: 1).location != NSNotFound {
            if let hours = Double(nsString.substring(with: match.range(at: 1))) {
                totalSeconds += hours * 3600
            }
        }
        
        // Minutes
        if match.range(at: 2).location != NSNotFound {
            if let minutes = Double(nsString.substring(with: match.range(at: 2))) {
                totalSeconds += minutes * 60
            }
        }
        
        // Seconds
        if match.range(at: 3).location != NSNotFound {
            if let seconds = Double(nsString.substring(with: match.range(at: 3))) {
                totalSeconds += seconds
            }
        }
        
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    /// Parses cover art URL, handling relative URLs
    /// - Parameters:
    ///   - urlString: The URL string from metadata
    ///   - baseURL: The base URL for resolving relative URLs
    /// - Returns: Absolute URL if valid
    private func parseCoverArtURL(_ urlString: String?, relativeTo baseURL: URL) -> URL? {
        guard let urlString = urlString else { return nil }
        
        // Try as absolute URL first
        if let absoluteURL = URL(string: urlString), absoluteURL.scheme != nil {
            return absoluteURL
        }
        
        // Try as relative URL
        return URL(string: urlString, relativeTo: baseURL)
    }
}
