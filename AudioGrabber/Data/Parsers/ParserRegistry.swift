//
//  ParserRegistry.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import OSLog

/// Registry for managing and selecting appropriate media parsers
@MainActor
final class ParserRegistry {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber.app", category: "ParserRegistry")
    
    /// Registered parsers, sorted by priority (highest first)
    private var parsers: [MediaParserProtocol] = []
    
    // MARK: - Singleton
    
    static let shared = ParserRegistry()
    
    private init() {
        registerDefaultParsers()
    }
    
    // MARK: - Registration
    
    /// Registers default parsers
    private func registerDefaultParsers() {
        // Register parsers in order (they will be sorted by priority)
        registerParser(GenericAudioParser())
        registerParser(JSONMetadataParser())
        
        logger.info("Registered \(self.parsers.count) default parser(s)")
    }
    
    /// Registers a new parser
    /// - Parameter parser: The parser to register
    func registerParser(_ parser: MediaParserProtocol) {
        parsers.append(parser)
        
        // Sort by priority (highest first)
        parsers.sort { $0.priority > $1.priority }
        
        logger.debug("Registered parser: \(parser.name) (priority: \(parser.priority))")
    }
    
    /// Unregisters a parser by name
    /// - Parameter name: The name of the parser to unregister
    func unregisterParser(named name: String) {
        parsers.removeAll { $0.name == name }
        logger.debug("Unregistered parser: \(name)")
    }
    
    /// Removes all registered parsers
    func clearParsers() {
        parsers.removeAll()
        logger.info("Cleared all parsers")
    }
    
    // MARK: - Parser Selection
    
    /// Gets the most appropriate parser for a given URL
    /// - Parameter url: The URL to parse
    /// - Returns: The best matching parser, or nil if none found
    func getParser(for url: URL) -> MediaParserProtocol? {
        logger.debug("Selecting parser for URL: \(url.absoluteString)")
        
        // Extract domain from URL
        let domain = url.host ?? ""
        
        // First, try to find a domain-specific parser
        if let domainParser = findDomainSpecificParser(for: domain) {
            logger.info("Selected domain-specific parser: \(domainParser.name)")
            return domainParser
        }
        
        // Fall back to universal parsers (those with empty supportedDomains)
        if let universalParser = findUniversalParser(for: url) {
            logger.info("Selected universal parser: \(universalParser.name)")
            return universalParser
        }
        
        logger.warning("No suitable parser found for URL: \(url.absoluteString)")
        return nil
    }
    
    /// Finds a domain-specific parser
    /// - Parameter domain: The domain to match
    /// - Returns: The highest priority parser that supports the domain
    private func findDomainSpecificParser(for domain: String) -> MediaParserProtocol? {
        // Parsers are already sorted by priority
        for parser in parsers {
            // Skip universal parsers
            guard !parser.supportedDomains.isEmpty else { continue }
            
            // Check if domain matches
            for supportedDomain in parser.supportedDomains {
                if domain.contains(supportedDomain) {
                    return parser
                }
            }
        }
        
        return nil
    }
    
    /// Finds a universal parser (one that supports all domains)
    /// - Parameter url: The URL to parse
    /// - Returns: The highest priority universal parser that can parse the URL
    private func findUniversalParser(for url: URL) -> MediaParserProtocol? {
        // Parsers are already sorted by priority
        for parser in parsers {
            // Only consider universal parsers
            guard parser.supportedDomains.isEmpty else { continue }
            
            // Check if parser can handle this URL
            if parser.canParse(url: url) {
                return parser
            }
        }
        
        return nil
    }
    
    // MARK: - Query Methods
    
    /// Gets all registered parsers
    /// - Returns: Array of all registered parsers, sorted by priority
    func getAllParsers() -> [MediaParserProtocol] {
        return parsers
    }
    
    /// Gets parsers that support a specific domain
    /// - Parameter domain: The domain to search for
    /// - Returns: Array of parsers that support the domain
    func getParsers(for domain: String) -> [MediaParserProtocol] {
        parsers.filter { parser in
            parser.supportedDomains.contains { supportedDomain in
                domain.contains(supportedDomain)
            }
        }
    }
    
    /// Gets a parser by name
    /// - Parameter name: The name of the parser
    /// - Returns: The parser if found
    func getParser(named name: String) -> MediaParserProtocol? {
        parsers.first { $0.name == name }
    }
    
    // MARK: - Debugging
    
    /// Prints information about all registered parsers
    func printRegisteredParsers() {
        logger.info("=== Registered Parsers ===")
        for (index, parser) in parsers.enumerated() {
            let domains = parser.supportedDomains.isEmpty ? "all domains" : parser.supportedDomains.joined(separator: ", ")
            logger.info("[\(index + 1)] \(parser.name) - Priority: \(parser.priority) - Domains: \(domains)")
        }
        logger.info("=========================")
    }
}
