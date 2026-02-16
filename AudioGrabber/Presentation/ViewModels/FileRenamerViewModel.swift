//
//  FileRenamerViewModel.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-13.
//

import Foundation
import SwiftUI
import AppKit
import OSLog

@MainActor
final class FileRenamerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var items: [RenameItem] = []
    @Published var isLoading: Bool = false
    @Published var isRenaming: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFolderURL: URL?
    @Published var renameProgress: Double = 0
    
    // MARK: - Computed Properties
    
    var selectedItems: [RenameItem] {
        items.filter { $0.isSelected && $0.canBeRenamed }
    }
    
    var selectedCount: Int {
        selectedItems.count
    }
    
    var totalCount: Int {
        items.count
    }
    
    var readyToRenameCount: Int {
        items.filter { $0.canBeRenamed }.count
    }
    
    var noTitleCount: Int {
        items.filter { $0.status == .noTitle }.count
    }
    
    var renamedCount: Int {
        items.filter { $0.status == .renamed }.count
    }
    
    var allSelected: Bool {
        get {
            let renamableItems = items.filter { $0.canBeRenamed }
            return !renamableItems.isEmpty && renamableItems.allSatisfy { $0.isSelected }
        }
        set {
            toggleSelectAll(newValue)
        }
    }
    
    // MARK: - Dependencies
    
    private let renamerService: FileRenamerService
    private let logger = Logger(subsystem: "AudioGrabber", category: "FileRenamerViewModel")
    
    // MARK: - Initialization
    
    init(renamerService: FileRenamerService = FileRenamerService()) {
        self.renamerService = renamerService
    }
    
    // MARK: - Public Methods
    
    /// Open file picker dialog to select a folder
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing audio files"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFolder(url)
        }
    }
    
    /// Load a folder (via drag & drop or selection)
    /// - Parameter url: URL of the folder to load
    func loadFolder(_ url: URL) {
        selectedFolderURL = url
        
        Task {
            await scanFolder(url)
        }
    }
    
    /// Scan a folder for audio files
    /// - Parameter url: URL of the folder to scan
    func scanFolder(_ url: URL) async {
        isLoading = true
        errorMessage = nil
        items = []
        
        do {
            let scannedItems = try await renamerService.scanFolder(at: url)
            items = scannedItems
            logger.info("Scanned \(scannedItems.count) files in folder: \(url.path)")
        } catch {
            errorMessage = "Failed to scan folder: \(error.localizedDescription)"
            logger.error("Scan error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Rename selected files
    func renameSelectedFiles() async {
        guard !selectedItems.isEmpty else {
            logger.warning("No items selected for renaming")
            return
        }
        
        isRenaming = true
        renameProgress = 0
        errorMessage = nil
        
        let itemsToRename = selectedItems
        let total = Double(itemsToRename.count)
        var completed = 0
        
        logger.info("Starting batch rename of \(itemsToRename.count) files")
        
        for item in itemsToRename {
            do {
                let renamedItem = try await renamerService.renameFile(item)
                
                // Update item in the list
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = renamedItem
                }
                
                completed += 1
                renameProgress = Double(completed) / total
                
            } catch {
                logger.error("Failed to rename file \(item.originalName): \(error.localizedDescription)")
                
                // Update item with failed status
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    var failedItem = item
                    failedItem.status = .failed(error.localizedDescription)
                    items[index] = failedItem
                }
                
                completed += 1
                renameProgress = Double(completed) / total
            }
        }
        
        isRenaming = false
        logger.info("Batch rename completed: \(completed) files processed")
    }
    
    /// Toggle selection for a specific item
    /// - Parameter item: The item to toggle selection for
    func toggleSelection(for item: RenameItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }
    
    /// Select or deselect all renamable items
    /// - Parameter select: true to select all, false to deselect all
    func toggleSelectAll(_ select: Bool) {
        for index in items.indices {
            if items[index].canBeRenamed {
                items[index].isSelected = select
            }
        }
    }
    
    /// Clear all items and reset state
    func clearItems() {
        items = []
        selectedFolderURL = nil
        errorMessage = nil
        renameProgress = 0
        logger.info("Cleared all items")
    }
}
