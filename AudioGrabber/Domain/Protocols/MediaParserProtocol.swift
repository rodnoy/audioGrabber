//
//  MediaParserProtocol.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Protocol defining the interface for media parsers that extract audio files from web pages.
///
/// Parsers implementing this protocol are responsible for analyzing HTML content
/// and extracting media items (audio files) from specific websites or platforms.
@MainActor
protocol MediaParserProtocol {
    /// Unique identifier for the parser (e.g., "soundcloud", "bandcamp")
    var identifier: String { get }
    
    /// Human-readable name for the parser (e.g., "SoundCloud Parser")
    var name: String { get }
    
    /// List of supported domain names (e.g., ["soundcloud.com", "m.soundcloud.com"])
    /// An empty array indicates a universal parser that can handle any domain
    var supportedDomains: [String] { get }
    
    /// Priority level for parser selection when multiple parsers support the same domain
    /// Higher values indicate higher priority (default: 0)
    var priority: Int { get }
    
    /// Determines whether this parser can handle the given URL
    ///
    /// - Parameter url: The URL to check
    /// - Returns: `true` if the parser can handle this URL, `false` otherwise
    func canParse(url: URL) -> Bool
    
    /// Parses HTML content to extract media items
    ///
    /// - Parameters:
    ///   - html: The HTML content to parse
    ///   - sourceURL: The original URL where the HTML was fetched from
    /// - Returns: A `ParserResult` containing extracted media items and metadata
    /// - Throws: `AppError.parsingError` if parsing fails
    func parse(html: String, sourceURL: URL) async throws -> ParserResult
}
