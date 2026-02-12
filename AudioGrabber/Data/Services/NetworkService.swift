//
//  NetworkService.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import OSLog

/// Network service for fetching web content
@MainActor
final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber.app", category: "NetworkService")
    private let session: URLSession
    
    /// User-Agent header to mimic a real browser
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    /// Request timeout in seconds
    private let timeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
        
        logger.info("NetworkService initialized with timeout: \(self.timeout)s")
    }
    
    /// Custom initializer for dependency injection (testing)
    /// - Parameter session: Custom URLSession
    init(session: URLSession) {
        self.session = session
        logger.info("NetworkService initialized with custom session")
    }
    
    // MARK: - NetworkServiceProtocol Implementation
    
    func fetchHTML(from url: URL) async throws -> String {
        logger.info("Fetching HTML from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw AppError.networkError(underlying: NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
            }
            
            logger.debug("Received response with status code: \(httpResponse.statusCode)")
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                throw AppError.networkError(underlying: NSError(domain: "NetworkService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"]))
            }
            
            // Detect encoding from response
            let encoding = detectEncoding(from: httpResponse, data: data)
            
            // Convert data to string
            guard let html = String(data: data, encoding: encoding) else {
                logger.error("Failed to decode response data")
                throw AppError.networkError(underlying: NSError(domain: "NetworkService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response data"]))
            }
            
            logger.info("Successfully fetched \(data.count) bytes of HTML content")
            
            return html
            
        } catch let error as AppError {
            throw error
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw AppError.networkError(underlying: error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Detects the text encoding from HTTP response headers or data
    /// - Parameters:
    ///   - response: The HTTP response
    ///   - data: The response data
    /// - Returns: The detected encoding, defaulting to UTF-8
    private func detectEncoding(from response: HTTPURLResponse, data: Data) -> String.Encoding {
        // Try to get encoding from Content-Type header
        if let contentType = response.value(forHTTPHeaderField: "Content-Type") {
            if let encoding = parseEncoding(from: contentType) {
                logger.debug("Detected encoding from Content-Type: \(encoding)")
                return encoding
            }
        }
        
        // Try to detect from HTML meta tags
        if let encoding = detectEncodingFromHTML(data) {
            logger.debug("Detected encoding from HTML meta tag: \(encoding)")
            return encoding
        }
        
        // Default to UTF-8
        logger.debug("Using default encoding: UTF-8")
        return .utf8
    }
    
    /// Parses encoding from Content-Type header
    /// - Parameter contentType: The Content-Type header value
    /// - Returns: The detected encoding
    private func parseEncoding(from contentType: String) -> String.Encoding? {
        let lowercased = contentType.lowercased()
        
        if lowercased.contains("charset=utf-8") {
            return .utf8
        } else if lowercased.contains("charset=iso-8859-1") || lowercased.contains("charset=latin1") {
            return .isoLatin1
        } else if lowercased.contains("charset=windows-1252") {
            return .windowsCP1252
        } else if lowercased.contains("charset=utf-16") {
            return .utf16
        }
        
        return nil
    }
    
    /// Detects encoding from HTML meta tags
    /// - Parameter data: The HTML data
    /// - Returns: The detected encoding
    private func detectEncodingFromHTML(_ data: Data) -> String.Encoding? {
        // Try to read first 1024 bytes as ASCII to find meta charset tag
        guard let prefix = String(data: data.prefix(1024), encoding: .ascii) else {
            return nil
        }
        
        let lowercased = prefix.lowercased()
        
        if lowercased.contains("charset=utf-8") || lowercased.contains("charset=\"utf-8\"") {
            return .utf8
        } else if lowercased.contains("charset=iso-8859-1") || lowercased.contains("charset=\"iso-8859-1\"") {
            return .isoLatin1
        } else if lowercased.contains("charset=windows-1252") || lowercased.contains("charset=\"windows-1252\"") {
            return .windowsCP1252
        }
        
        return nil
    }
}

// MARK: - URLSession Extension for Redirect Handling

extension URLSession {
    /// Custom data task that handles redirects
    /// Note: URLSession already handles redirects by default, but this can be customized if needed
    func dataWithRedirects(for request: URLRequest) async throws -> (Data, URLResponse) {
        // URLSession handles redirects automatically
        // This method is here for potential future customization
        return try await data(for: request)
    }
}
