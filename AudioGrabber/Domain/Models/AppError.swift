//
//  AppError.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Application-specific errors with localized descriptions.
///
/// This enum defines all possible errors that can occur throughout the application,
/// providing user-friendly error messages for display in the UI.
enum AppError: LocalizedError, Sendable {
    /// The provided URL is invalid or malformed
    case invalidURL
    
    /// A network operation failed
    case networkError(underlying: Error)
    
    /// Parsing of HTML content failed
    case parsingError(message: String)
    
    /// No media items were found at the provided URL
    case noMediaFound
    
    /// A download operation failed
    case downloadFailed(underlying: Error)
    
    /// A file system operation failed
    case fileSystemError(message: String)
    
    /// Localized description of the error for display to users
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid or malformed."
            
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
            
        case .parsingError(let message):
            return "Failed to parse media content: \(message)"
            
        case .noMediaFound:
            return "No audio files were found at the provided URL."
            
        case .downloadFailed(let underlying):
            return "Download failed: \(underlying.localizedDescription)"
            
        case .fileSystemError(let message):
            return "File system error: \(message)"
        }
    }
    
    /// Failure reason providing additional context
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "The URL format is not recognized or is incomplete."
            
        case .networkError:
            return "Unable to connect to the server or retrieve data."
            
        case .parsingError:
            return "The page structure may have changed or is not supported."
            
        case .noMediaFound:
            return "The page does not contain any downloadable audio files."
            
        case .downloadFailed:
            return "The file could not be downloaded from the server."
            
        case .fileSystemError:
            return "Unable to read from or write to the file system."
        }
    }
    
    /// Recovery suggestion for the user
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please check the URL and try again."
            
        case .networkError:
            return "Check your internet connection and try again."
            
        case .parsingError:
            return "Try a different URL or contact support if the issue persists."
            
        case .noMediaFound:
            return "Verify that the URL contains audio files and try again."
            
        case .downloadFailed:
            return "Check your internet connection and available disk space, then try again."
            
        case .fileSystemError:
            return "Check disk space and file permissions, then try again."
        }
    }
}
