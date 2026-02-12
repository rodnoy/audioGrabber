//
//  MainViewModel.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation
import SwiftUI
import AppKit

@MainActor
@Observable
final class MainViewModel {
    // MARK: - State
    
    var urlString: String = ""
    var mediaItems: [MediaItem] = []
    var selectedItems: Set<UUID> = []
    var downloadDirectory: URL?
    var state: AppState = .idle
    var errorMessage: String?
    var downloadProgress: [UUID: Double] = [:]
    
    // MARK: - Dependencies
    
    private let parserRegistry: ParserRegistry
    private let networkService: NetworkServiceProtocol
    private let downloadManager: DownloadServiceProtocol
    
    // MARK: - Types
    
    enum AppState: Equatable {
        case idle
        case analyzing
        case resultsReady
        case downloading
        case completed
        case error
    }
    
    // MARK: - Initialization
    
    init(
        parserRegistry: ParserRegistry = .shared,
        networkService: NetworkServiceProtocol? = nil,
        downloadManager: DownloadServiceProtocol? = nil
    ) {
        self.parserRegistry = parserRegistry
        self.networkService = networkService ?? NetworkService()
        self.downloadManager = downloadManager ?? DownloadManager()
    }
    
    // MARK: - Actions
    
    func analyzeURL() async {
        guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a valid URL"
            state = .error
            return
        }
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL format"
            state = .error
            return
        }
        
        state = .analyzing
        errorMessage = nil
        mediaItems = []
        selectedItems = []
        downloadProgress = [:]
        
        do {
            guard let parser = parserRegistry.getParser(for: url) else {
                errorMessage = "No suitable parser found for this URL"
                state = .error
                return
            }
            
            // Fetch HTML content
            let html = try await networkService.fetchHTML(from: url)
            
            // Parse HTML to extract media items
            let result = try await parser.parse(html: html, sourceURL: url)
            
            mediaItems = result.items
            
            if result.items.isEmpty {
                errorMessage = "No audio files found at this URL"
                state = .error
            } else {
                state = .resultsReady
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }
    
    func toggleSelection(for item: MediaItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
    
    func selectAll() {
        selectedItems = Set(mediaItems.map { $0.id })
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    func downloadSelected() async {
        guard !selectedItems.isEmpty else {
            errorMessage = "Please select at least one file to download"
            state = .error
            return
        }
        
        guard let directory = downloadDirectory else {
            errorMessage = "Please choose a download directory"
            state = .error
            return
        }
        
        state = .downloading
        errorMessage = nil
        
        let itemsToDownload = mediaItems.filter { selectedItems.contains($0.id) }
        
        do {
            for item in itemsToDownload {
                downloadProgress[item.id] = 0.0
                
                let _ = try await downloadManager.download(
                    from: item.url,
                    to: directory,
                    filename: item.filename,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            self?.downloadProgress[item.id] = progress
                        }
                    }
                )
            }
            
            state = .completed
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }
    
    func cancelDownloads() {
        downloadManager.cancelAllDownloads()
        state = .resultsReady
        downloadProgress.removeAll()
    }
    
    func chooseDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Download Location"
        panel.message = "Select a folder where audio files will be saved"
        
        if panel.runModal() == .OK {
            downloadDirectory = panel.url
        }
    }
    
    func reset() {
        urlString = ""
        mediaItems = []
        selectedItems = []
        downloadProgress = [:]
        errorMessage = nil
        state = .idle
    }
    
    // MARK: - Computed Properties
    
    var isAnalyzing: Bool {
        state == .analyzing
    }
    
    var isDownloading: Bool {
        state == .downloading
    }
    
    var canAnalyze: Bool {
        state != .analyzing && state != .downloading
    }
    
    var canDownload: Bool {
        state == .resultsReady && !selectedItems.isEmpty && downloadDirectory != nil
    }
    
    var selectedCount: Int {
        selectedItems.count
    }
    
    var totalCount: Int {
        mediaItems.count
    }
    
    var overallProgress: Double {
        guard !downloadProgress.isEmpty else { return 0.0 }
        let total = downloadProgress.values.reduce(0.0, +)
        return total / Double(downloadProgress.count)
    }
}
