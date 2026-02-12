//
//  NetworkServiceProtocol.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Protocol defining the interface for network operations.
///
/// This protocol abstracts network communication, allowing for easy testing
/// and potential implementation swapping (e.g., URLSession, custom networking).
protocol NetworkServiceProtocol: Sendable {
    /// Fetches HTML content from the specified URL
    ///
    /// - Parameter url: The URL to fetch HTML from
    /// - Returns: The HTML content as a string
    /// - Throws: `AppError.networkError` if the request fails or `AppError.invalidURL` if the URL is malformed
    func fetchHTML(from url: URL) async throws -> String
}
