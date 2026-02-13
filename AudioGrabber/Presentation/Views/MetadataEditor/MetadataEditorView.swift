//
//  MetadataEditorView.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import SwiftUI

struct MetadataEditorView: View {
    @State private var viewModel: MetadataEditorViewModel
    
    init(metadataService: MetadataServiceProtocol) {
        self._viewModel = State(initialValue: MetadataEditorViewModel(metadataService: metadataService))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // File Drop Zone
                if viewModel.selectedFileURL == nil {
                    VStack(spacing: 16) {
                        FileDropZone(
                            onFileDrop: { url in
                                Task {
                                    await viewModel.loadFile(from: url)
                                }
                            },
                            selectedFileName: nil
                        )
                        
                        Text("or")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        
                        Button {
                            viewModel.selectFile()
                        } label: {
                            Label("Open File...", systemImage: "folder")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                } else {
                    // File info header
                    fileInfoHeader
                }
                
                // Main content (only shown when file is loaded)
                if let metadata = viewModel.metadata {
                    contentView(metadata: metadata)
                }
                
                // Messages
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
                
                if let successMessage = viewModel.successMessage {
                    successBanner(message: successMessage)
                }
            }
            .padding()
        }
        .frame(minWidth: 800, minHeight: 600)
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }
    
    // MARK: - Subviews
    
    private var fileInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Selected File", systemImage: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let url = viewModel.selectedFileURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    if let url = viewModel.selectedFileURL {
                        await viewModel.loadFile(from: url)
                    }
                }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            
            Button {
                viewModel.selectedFileURL = nil
                viewModel.metadata = nil
                viewModel.originalMetadata = nil
            } label: {
                Label("Close", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func contentView(metadata: AudioFileMetadata) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column: Artwork
            VStack {
                ArtworkView(
                    artwork: metadata.artwork,
                    onSave: {
                        Task {
                            await saveArtwork()
                        }
                    },
                    onReplace: { url in
                        Task {
                            await viewModel.importArtwork(from: url)
                        }
                    },
                    onRemove: {
                        viewModel.removeArtwork()
                    }
                )
                
                Spacer()
            }
            .frame(width: 300)
            
            // Right column: Form and Technical Info
            VStack(spacing: 20) {
                // Metadata form
                if var editableMetadata = viewModel.metadata {
                    MetadataFormView(metadata: Binding(
                        get: { viewModel.metadata ?? editableMetadata },
                        set: { viewModel.metadata = $0 }
                    ))
                }
                
                // Technical information
                TechnicalInfoView(metadata: metadata)
                
                // Action buttons
                actionButtons
            }
        }
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.hasUnsavedChanges {
                Button(role: .destructive) {
                    viewModel.discardChanges()
                } label: {
                    Label("Discard Changes", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.saveChanges()
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }
                Label("Save Changes", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                
                Text("Loading metadata...")
                    .font(.headline)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(radius: 10)
            )
        }
    }
    
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.body)
            
            Spacer()
            
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private func successBanner(message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(message)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func saveArtwork() async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "artwork.png"
        panel.message = "Save album artwork"
        
        let response = await panel.begin()
        
        if response == .OK, let url = panel.url {
            do {
                _ = try await viewModel.exportArtwork(to: url.deletingLastPathComponent())
            } catch {
                viewModel.errorMessage = "Failed to save artwork: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    MetadataEditorView(metadataService: MetadataService())
        .frame(width: 900, height: 700)
}
