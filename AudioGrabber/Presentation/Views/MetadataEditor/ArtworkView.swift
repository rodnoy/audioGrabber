//
//  ArtworkView.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import SwiftUI
import UniformTypeIdentifiers

struct ArtworkView: View {
    let artwork: NSImage?
    let onSave: () -> Void
    let onReplace: (URL) -> Void
    let onRemove: () -> Void
    
    @State private var isTargeted: Bool = false
    @State private var showingSavePanel: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Album Artwork")
                .font(.headline)
            
            // Artwork display
            ZStack {
                if let image = artwork {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No Artwork")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                
                // Drop overlay
                if isTargeted {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.blue, lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .frame(width: 250, height: 250)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if artwork != nil {
                    Button {
                        saveArtwork()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    openImagePicker()
                } label: {
                    Label(artwork != nil ? "Replace" : "Add", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                
                if artwork != nil {
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Text("Drop an image here or click to select")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Supported: PNG, JPEG")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Private Methods
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            // Validate image file
            if isImageFile(url) {
                DispatchQueue.main.async {
                    onReplace(url)
                }
            }
        }
        
        return true
    }
    
    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg]
        panel.message = "Select an image for album artwork"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onReplace(url)
            }
        }
    }
    
    private func saveArtwork() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "artwork.png"
        panel.message = "Save album artwork"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    onSave()
                }
            }
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

#Preview {
    VStack(spacing: 20) {
        // With artwork
        ArtworkView(
            artwork: NSImage(systemSymbolName: "music.note", accessibilityDescription: nil),
            onSave: {},
            onReplace: { _ in },
            onRemove: {}
        )
        
        // Without artwork
        ArtworkView(
            artwork: nil,
            onSave: {},
            onReplace: { _ in },
            onRemove: {}
        )
    }
    .padding()
    .frame(width: 400)
}
