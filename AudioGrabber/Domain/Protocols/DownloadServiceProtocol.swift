//
//  DownloadServiceProtocol.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Protocol defining the interface for downloading media files.
///
/// This protocol handles the actual download of audio files from URLs,
/// supporting both single and batch downloads with progress tracking.
@MainActor
protocol DownloadServiceProtocol {
    /// Downloads a file from a URL to the specified directory
    ///
    /// - Parameters:
    ///   - url: The URL to download from
    ///   - destinationDirectory: The destination directory for the downloaded file
    ///   - filename: Optional custom filename (uses URL's filename if nil)
    ///   - progressHandler: A closure called periodically with download progress (0.0 to 1.0)
    /// - Returns: The URL of the downloaded file
    /// - Throws: `AppError.downloadFailed` if the download fails or `AppError.fileSystemError` if file operations fail
    func download(
        from url: URL,
        to destinationDirectory: URL,
        filename: String?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL
    
    /// Cancels all active downloads
    func cancelAllDownloads()
}
