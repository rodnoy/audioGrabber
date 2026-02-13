//
//  FileDropZone.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: View {
    let onFileDrop: (URL) -> Void
    let selectedFileName: String?
    
    @State private var isTargeted: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(isTargeted ? .blue : .secondary)
            
            if let fileName = selectedFileName {
                VStack(spacing: 4) {
                    Text("Selected File:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(fileName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                Text("Drop an audio file here")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Choose File") {
                    openFilePicker()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Supported formats: MP3, M4A, FLAC, WAV")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.blue.opacity(0.05) : Color.clear)
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            // Validate audio file
            if isAudioFile(url) {
                // macOS automatically provides security-scoped URLs for drag-and-drop
                // The URL will be security-scoped and we need to call startAccessingSecurityScopedResource
                DispatchQueue.main.async {
                    onFileDrop(url)
                }
            }
        }
        
        return true
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .mp3,
            .mpeg4Audio,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "flac") ?? .audio,
            .wav
        ]
        panel.message = "Select an audio file to edit metadata"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onFileDrop(url)
            }
        }
    }
    
    private func isAudioFile(_ url: URL) -> Bool {
        let audioExtensions = ["mp3", "m4a", "flac", "wav", "aac", "ogg"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
}

#Preview {
    VStack(spacing: 20) {
        FileDropZone(onFileDrop: { _ in }, selectedFileName: nil)
            .padding()
        
        FileDropZone(onFileDrop: { _ in }, selectedFileName: "Example Song.mp3")
            .padding()
    }
    .frame(width: 500)
}
