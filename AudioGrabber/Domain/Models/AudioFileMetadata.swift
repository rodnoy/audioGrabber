//
//  AudioFileMetadata.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import AppKit

/// Represents metadata for an audio file
struct AudioFileMetadata: Equatable {
    // MARK: - Editable Metadata
    
    /// Track title
    var title: String?
    
    /// Artist name
    var artist: String?
    
    /// Album name
    var album: String?
    
    /// Album artist name
    var albumArtist: String?
    
    /// Composer name
    var composer: String?
    
    /// Genre
    var genre: String?
    
    /// Release year
    var year: Int?
    
    /// Track number in album
    var trackNumber: Int?
    
    /// Total number of tracks in album
    var trackTotal: Int?
    
    /// Disc number in multi-disc album
    var discNumber: Int?
    
    /// Total number of discs
    var discTotal: Int?
    
    /// Comment or description
    var comment: String?
    
    /// Song lyrics
    var lyrics: String?
    
    /// Album artwork/cover image
    var artwork: NSImage?
    
    // MARK: - Technical Information (Read-only)
    
    /// Duration in seconds
    let duration: TimeInterval?
    
    /// Bitrate in bits per second
    let bitrate: Int?
    
    /// Sample rate in Hz
    let sampleRate: Int?
    
    /// Number of audio channels
    let channels: Int?
    
    /// File format (e.g., "mp3", "m4a", "wav")
    let fileFormat: String?
    
    /// File size in bytes
    let fileSize: Int64?
    
    // MARK: - Initialization
    
    init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        composer: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        trackTotal: Int? = nil,
        discNumber: Int? = nil,
        discTotal: Int? = nil,
        comment: String? = nil,
        lyrics: String? = nil,
        artwork: NSImage? = nil,
        duration: TimeInterval? = nil,
        bitrate: Int? = nil,
        sampleRate: Int? = nil,
        channels: Int? = nil,
        fileFormat: String? = nil,
        fileSize: Int64? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.composer = composer
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.trackTotal = trackTotal
        self.discNumber = discNumber
        self.discTotal = discTotal
        self.comment = comment
        self.lyrics = lyrics
        self.artwork = artwork
        self.duration = duration
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels
        self.fileFormat = fileFormat
        self.fileSize = fileSize
    }
    
    // MARK: - Equatable
    
    static func == (lhs: AudioFileMetadata, rhs: AudioFileMetadata) -> Bool {
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
        lhs.albumArtist == rhs.albumArtist &&
        lhs.composer == rhs.composer &&
        lhs.genre == rhs.genre &&
        lhs.year == rhs.year &&
        lhs.trackNumber == rhs.trackNumber &&
        lhs.trackTotal == rhs.trackTotal &&
        lhs.discNumber == rhs.discNumber &&
        lhs.discTotal == rhs.discTotal &&
        lhs.comment == rhs.comment &&
        lhs.lyrics == rhs.lyrics &&
        lhs.artwork?.tiffRepresentation == rhs.artwork?.tiffRepresentation &&
        lhs.duration == rhs.duration &&
        lhs.bitrate == rhs.bitrate &&
        lhs.sampleRate == rhs.sampleRate &&
        lhs.channels == rhs.channels &&
        lhs.fileFormat == rhs.fileFormat &&
        lhs.fileSize == rhs.fileSize
    }
}
