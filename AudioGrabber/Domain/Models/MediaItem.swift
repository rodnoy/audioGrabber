//
//  MediaItem.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import Foundation

/// Represents a single audio media item discovered by a parser.
///
/// This model contains all necessary information about an audio file,
/// including its URL, metadata, and selection state for batch operations.
struct MediaItem: Identifiable, Hashable, Sendable {
    /// Unique identifier for the media item
    let id: UUID
    
    /// Direct URL to the audio file
    let url: URL
    
    /// Suggested filename for saving the file
    let fileName: String
    
    /// Human-readable display name for the UI
    let displayName: String
    
    /// Audio file format/extension
    let fileExtension: AudioFormat
    
    /// File size in bytes, if known
    let fileSize: Int64?
    
    /// Optional metadata about the audio file
    let metadata: MediaMetadata?
    
    /// Selection state for batch downloads
    var isSelected: Bool
    
    // MARK: - Computed Properties
    
    /// Title for display (uses metadata title or display name)
    var title: String {
        metadata?.title ?? displayName
    }
    
    /// Duration from metadata
    var duration: TimeInterval? {
        metadata?.duration
    }
    
    /// Filename for download
    var filename: String {
        fileName
    }
    
    /// Creates a new media item
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - url: Direct URL to the audio file
    ///   - fileName: Suggested filename for saving
    ///   - displayName: Human-readable name for display
    ///   - fileExtension: Audio format
    ///   - fileSize: Optional file size in bytes
    ///   - metadata: Optional audio metadata
    ///   - isSelected: Initial selection state (defaults to true)
    init(
        id: UUID = UUID(),
        url: URL,
        fileName: String,
        displayName: String,
        fileExtension: AudioFormat,
        fileSize: Int64? = nil,
        metadata: MediaMetadata? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.displayName = displayName
        self.fileExtension = fileExtension
        self.fileSize = fileSize
        self.metadata = metadata
        self.isSelected = isSelected
    }
}

/// Supported audio file formats
enum AudioFormat: String, CaseIterable, Sendable {
    case mp3
    case m4a
    case wav
    case ogg
    case flac
    case aac
    case opus
    
    /// Human-readable format name
    var displayName: String {
        switch self {
        case .mp3: return "MP3"
        case .m4a: return "M4A (AAC)"
        case .wav: return "WAV"
        case .ogg: return "OGG Vorbis"
        case .flac: return "FLAC"
        case .aac: return "AAC"
        case .opus: return "Opus"
        }
    }
    
    /// MIME type for the audio format
    var mimeType: String {
        switch self {
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/mp4"
        case .wav: return "audio/wav"
        case .ogg: return "audio/ogg"
        case .flac: return "audio/flac"
        case .aac: return "audio/aac"
        case .opus: return "audio/opus"
        }
    }
}

/// Metadata associated with an audio file
struct MediaMetadata: Hashable, Sendable {
    /// Track title
    let title: String?
    
    /// Artist name
    let artist: String?
    
    /// Album name
    let album: String?
    
    /// Duration in seconds
    let duration: TimeInterval?
    
    /// Creates new media metadata
    ///
    /// - Parameters:
    ///   - title: Optional track title
    ///   - artist: Optional artist name
    ///   - album: Optional album name
    ///   - duration: Optional duration in seconds
    init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
    }
}
