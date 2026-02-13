//
//  MetadataFormView.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import SwiftUI

struct MetadataFormView: View {
    @Binding var metadata: AudioFileMetadata
    
    @State private var isLyricsExpanded: Bool = false
    
    var body: some View {
        Form {
            Section("Basic Information") {
                LabeledContent("Title") {
                    TextField("Title", text: binding(for: \.title), prompt: Text("Song Title"))
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Artist") {
                    TextField("Artist", text: binding(for: \.artist), prompt: Text("Artist Name"))
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Album") {
                    TextField("Album", text: binding(for: \.album), prompt: Text("Album Name"))
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Album Artist") {
                    TextField("Album Artist", text: binding(for: \.albumArtist), prompt: Text("Album Artist"))
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            Section("Additional Information") {
                LabeledContent("Composer") {
                    TextField("Composer", text: binding(for: \.composer), prompt: Text("Composer Name"))
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Genre") {
                    TextField("Genre", text: binding(for: \.genre), prompt: Text("Genre"))
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Year") {
                    TextField("Year", value: binding(for: \.year), format: .number, prompt: Text("YYYY"))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }
            
            Section("Track Information") {
                HStack {
                    LabeledContent("Track") {
                        HStack(spacing: 8) {
                            TextField("No.", value: binding(for: \.trackNumber), format: .number, prompt: Text("1"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            
                            Text("/")
                                .foregroundStyle(.secondary)
                            
                            TextField("Total", value: binding(for: \.trackTotal), format: .number, prompt: Text("12"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                        }
                    }
                    
                    Spacer()
                    
                    LabeledContent("Disc") {
                        HStack(spacing: 8) {
                            TextField("No.", value: binding(for: \.discNumber), format: .number, prompt: Text("1"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            
                            Text("/")
                                .foregroundStyle(.secondary)
                            
                            TextField("Total", value: binding(for: \.discTotal), format: .number, prompt: Text("2"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                        }
                    }
                }
            }
            
            Section("Comments & Lyrics") {
                LabeledContent("Comment") {
                    TextEditor(text: binding(for: \.comment))
                        .frame(height: 60)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .alignmentGuide(.labeledContentAlignmentGuide) { d in d[.top] }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Lyrics", systemImage: "text.quote")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                isLyricsExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isLyricsExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if isLyricsExpanded {
                        TextEditor(text: binding(for: \.lyrics))
                            .frame(height: 200)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Helper Methods
    
    private func binding<T>(for keyPath: WritableKeyPath<AudioFileMetadata, T?>) -> Binding<T> where T: _DefaultInitializable {
        Binding(
            get: { metadata[keyPath: keyPath] ?? T() },
            set: { metadata[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
    
    private func binding<T>(for keyPath: WritableKeyPath<AudioFileMetadata, T?>) -> Binding<T> where T: BinaryInteger {
        Binding(
            get: { metadata[keyPath: keyPath] ?? 0 },
            set: { metadata[keyPath: keyPath] = $0 == 0 ? nil : $0 }
        )
    }
}

// MARK: - Helper Protocol

protocol _DefaultInitializable {
    init()
    var isEmpty: Bool { get }
}

extension String: _DefaultInitializable {}

// MARK: - Alignment Guide

extension VerticalAlignment {
    private struct LabeledContentAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let labeledContentAlignmentGuide = VerticalAlignment(LabeledContentAlignment.self)
}

#Preview {
    @Previewable @State var metadata = AudioFileMetadata(
        title: "Example Song",
        artist: "Example Artist",
        album: "Example Album",
        genre: "Rock",
        year: 2024,
        trackNumber: 1,
        trackTotal: 12,
        discNumber: 1,
        discTotal: 1,
        comment: "This is a comment",
        lyrics: "These are the lyrics\nLine 2\nLine 3",
        duration: 180.0,
        bitrate: 320,
        sampleRate: 44100,
        channels: 2,
        fileFormat: "MP3",
        fileSize: 7200000
    )
    
    ScrollView {
        MetadataFormView(metadata: $metadata)
            .padding()
    }
    .frame(width: 600, height: 700)
}
