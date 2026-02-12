//
//  ParserResult.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Result of a parsing operation containing extracted media items and metadata.
///
/// This structure encapsulates the output of a parser, including all discovered
/// media items, warnings, and information about which parser was used.
struct ParserResult: Sendable {
    /// Array of media items extracted from the source
    let items: [MediaItem]
    
    /// Identifier of the parser that produced this result
    let parserIdentifier: String
    
    /// Array of warning messages generated during parsing
    /// (e.g., "Could not extract duration for track 3")
    let warnings: [String]
    
    /// The original URL that was parsed
    let sourceURL: URL
    
    /// Creates a new parser result
    ///
    /// - Parameters:
    ///   - items: Extracted media items
    ///   - parserIdentifier: Identifier of the parser used
    ///   - warnings: Optional array of warning messages
    ///   - sourceURL: The source URL that was parsed
    init(
        items: [MediaItem],
        parserIdentifier: String,
        warnings: [String] = [],
        sourceURL: URL
    ) {
        self.items = items
        self.parserIdentifier = parserIdentifier
        self.warnings = warnings
        self.sourceURL = sourceURL
    }
}
