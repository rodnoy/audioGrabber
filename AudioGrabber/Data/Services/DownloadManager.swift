//
//  DownloadManager.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import OSLog

/// Download manager for handling audio file downloads with progress tracking
@MainActor
final class DownloadManager: NSObject, DownloadServiceProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.audiograbber.app", category: "DownloadManager")
    
    private var session: URLSession!
    private var activeDownloads: [UUID: DownloadTask] = [:]
    
    /// Thread-safe mapping from URLSessionTask to task ID for delegate callbacks
    private let taskMapping = NSMapTable<URLSessionTask, NSUUID>.strongToStrongObjects()
    private let taskMappingLock = NSLock()
    
    /// User-Agent header to mimic a real browser
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    // MARK: - Internal Types
    
    /// Internal representation of an active download
    private class DownloadTask {
        let id: UUID
        let url: URL
        let destinationURL: URL
        var downloadTask: URLSessionDownloadTask?
        var progressHandler: ((Double) -> Void)?
        var completionHandler: ((Result<URL, AppError>) -> Void)?
        
        init(id: UUID, url: URL, destinationURL: URL) {
            self.id = id
            self.url = url
            self.destinationURL = destinationURL
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 300.0 // 5 minutes for large files
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        logger.info("DownloadManager initialized")
    }
    
    // MARK: - DownloadServiceProtocol Implementation
    
    func download(
        from url: URL,
        to destinationDirectory: URL,
        filename: String?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        logger.info("Starting download from: \(url.absoluteString)")
        
        // Determine final filename
        let finalFilename = filename ?? url.lastPathComponent
        var destinationURL = destinationDirectory.appendingPathComponent(finalFilename)
        
        // Handle filename conflicts
        destinationURL = resolveFilenameConflict(at: destinationURL)
        
        logger.debug("Destination: \(destinationURL.path)")
        
        // Create download task
        let downloadID = UUID()
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = DownloadTask(id: downloadID, url: url, destinationURL: destinationURL)
            task.progressHandler = progressHandler
            task.completionHandler = { result in
                continuation.resume(with: result)
            }
            
            // Create URLRequest with headers
            var request = URLRequest(url: url)
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            
            // Create and start download task
            let downloadTask = session.downloadTask(with: request)
            task.downloadTask = downloadTask
            
            activeDownloads[downloadID] = task
            
            // Register task mapping for thread-safe access in delegate callbacks
            taskMappingLock.lock()
            taskMapping.setObject(downloadID as NSUUID, forKey: downloadTask)
            taskMappingLock.unlock()
            
            downloadTask.resume()
            
            logger.debug("Download task started with ID: \(downloadID)")
        }
    }
    
    func cancelDownload(id: UUID) {
        logger.info("Cancelling download: \(id)")
        
        guard let task = activeDownloads[id] else {
            logger.warning("Download task not found: \(id)")
            return
        }
        
        // Clean up task mapping
        if let downloadTask = task.downloadTask {
            taskMappingLock.lock()
            taskMapping.removeObject(forKey: downloadTask)
            taskMappingLock.unlock()
        }
        
        task.downloadTask?.cancel()
        activeDownloads.removeValue(forKey: id)
        
        logger.debug("Download cancelled: \(id)")
    }
    
    func cancelAllDownloads() {
        logger.info("Cancelling all downloads (\(self.activeDownloads.count) active)")
        
        for (_, task) in self.activeDownloads {
            // Clean up task mapping
            if let downloadTask = task.downloadTask {
                taskMappingLock.lock()
                taskMapping.removeObject(forKey: downloadTask)
                taskMappingLock.unlock()
            }
            
            task.downloadTask?.cancel()
        }
        
        self.activeDownloads.removeAll()
        
        logger.debug("All downloads cancelled")
    }
    
    // MARK: - Helper Methods
    
    /// Resolves filename conflicts by appending a number
    /// - Parameter url: The proposed destination URL
    /// - Returns: A unique URL that doesn't conflict with existing files
    private func resolveFilenameConflict(at url: URL) -> URL {
        var destinationURL = url
        var counter = 1
        
        let fileManager = FileManager.default
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        
        while fileManager.fileExists(atPath: destinationURL.path) {
            let newFilename = "\(filename) (\(counter)).\(fileExtension)"
            destinationURL = directory.appendingPathComponent(newFilename)
            counter += 1
        }
        
        if counter > 1 {
            logger.debug("Resolved filename conflict: \(destinationURL.lastPathComponent)")
        }
        
        return destinationURL
    }
    
    /// Finds the download task associated with a URLSessionTask
    /// - Parameter sessionTask: The URLSessionTask
    /// - Returns: The corresponding DownloadTask if found
    private func findDownloadTask(for sessionTask: URLSessionTask) -> DownloadTask? {
        activeDownloads.values.first { $0.downloadTask === sessionTask }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // CRITICAL: File operations must be performed SYNCHRONOUSLY within this callback
        // because the temporary file at 'location' will be deleted immediately after this method returns.
        // We cannot use Task { @MainActor } here as it would execute asynchronously.
        
        let fileManager = FileManager.default
        
        // Get task ID from thread-safe mapping
        taskMappingLock.lock()
        let taskID = taskMapping.object(forKey: downloadTask) as? UUID
        taskMappingLock.unlock()
        
        guard let taskID = taskID else {
            logger.error("Download task not found for completed download")
            return
        }
        
        // Perform file operations synchronously
        let result: Result<(UUID, URL, URL), Error> = Result {
            // We need to get the destination URL synchronously before the file is deleted
            // Store it in a local variable to avoid MainActor access issues
            var destinationURL: URL?
            
            // Quick synchronous read of destination URL
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                if let task = self.activeDownloads[taskID] {
                    destinationURL = task.destinationURL
                }
                semaphore.signal()
            }
            semaphore.wait()
            
            guard let destination = destinationURL else {
                throw NSError(domain: "DownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download task not found"])
            }
            
            logger.info("Download completed: \(taskID)")
            
            // Ensure destination directory exists
            let destinationDirectory = destination.deletingLastPathComponent()
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            
            // Remove existing file if it exists (shouldn't happen due to conflict resolution)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            
            // COPY (not move) the file - more reliable with temporary files
            try fileManager.copyItem(at: location, to: destination)
            
            logger.info("File saved to: \(destination.path)")
            
            return (taskID, destination, location)
        }
        
        // Now dispatch to MainActor to update state and call completion handlers
        Task { @MainActor in
            // Clean up task mapping
            taskMappingLock.lock()
            taskMapping.removeObject(forKey: downloadTask)
            taskMappingLock.unlock()
            
            switch result {
            case .success(let (taskID, destinationURL, _)):
                if let task = activeDownloads[taskID] {
                    task.completionHandler?(.success(destinationURL))
                    activeDownloads.removeValue(forKey: taskID)
                }
                
            case .failure(let error):
                logger.error("Failed to save downloaded file: \(error.localizedDescription)")
                
                if let task = activeDownloads[taskID] {
                    task.completionHandler?(.failure(.downloadFailed(underlying: error)))
                    activeDownloads.removeValue(forKey: taskID)
                }
            }
        }
    }
    
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        // Get task ID from thread-safe mapping
        taskMappingLock.lock()
        let taskID = taskMapping.object(forKey: downloadTask) as? UUID
        taskMappingLock.unlock()
        
        Task { @MainActor in
            guard let taskID = taskID else {
                return
            }
            
            guard let task = activeDownloads[taskID] else {
                return
            }
            
            // Calculate progress
            let progress: Double
            if totalBytesExpectedToWrite > 0 {
                progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            } else {
                progress = 0.0
            }
            
            // Call progress handler
            task.progressHandler?(progress)
            
            logger.debug("Download progress: \(taskID) - \(Int(progress * 100))%")
        }
    }
    
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // Get task ID from thread-safe mapping
        taskMappingLock.lock()
        let taskID = taskMapping.object(forKey: task) as? UUID
        taskMappingLock.unlock()
        
        Task { @MainActor in
            guard let taskID = taskID else {
                return
            }
            
            guard let downloadTask = activeDownloads[taskID] else {
                return
            }
            
            if let error = error {
                logger.error("Download failed: \(taskID) - \(error.localizedDescription)")
                
                let appError: AppError
                if (error as NSError).code == NSURLErrorCancelled {
                    appError = .downloadFailed(underlying: NSError(domain: "DownloadManager", code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey: "Download cancelled"]))
                } else {
                    appError = .downloadFailed(underlying: error)
                }
                
                downloadTask.completionHandler?(.failure(appError))
                activeDownloads.removeValue(forKey: taskID)
                
                // Clean up task mapping
                if let sessionTask = task as? URLSessionDownloadTask {
                    taskMappingLock.lock()
                    taskMapping.removeObject(forKey: sessionTask)
                    taskMappingLock.unlock()
                }
            }
            // Success case is handled in didFinishDownloadingTo
        }
    }
}

// MARK: - URLSessionTaskDelegate

extension DownloadManager: URLSessionTaskDelegate {
    
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Allow redirects
        Task { @MainActor in
            logger.debug("Following redirect to: \(request.url?.absoluteString ?? "unknown")")
            completionHandler(request)
        }
    }
}
