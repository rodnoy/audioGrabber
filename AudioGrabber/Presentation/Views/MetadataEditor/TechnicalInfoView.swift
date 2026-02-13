//
//  TechnicalInfoView.swift
//  AudioGrabber
//
//  Created by AudioGrabber on 2026-02-12.
//

import SwiftUI

struct TechnicalInfoView: View {
    let metadata: AudioFileMetadata
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Technical Information", systemImage: "info.circle")
                    .font(.headline)
                
                Divider()
                
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        InfoLabel(icon: "clock", title: "Duration")
                        InfoValue(formattedDuration)
                        
                        InfoLabel(icon: "waveform", title: "Bitrate")
                        InfoValue(formattedBitrate)
                    }
                    
                    GridRow {
                        InfoLabel(icon: "waveform.path", title: "Sample Rate")
                        InfoValue(formattedSampleRate)
                        
                        InfoLabel(icon: "speaker.wave.2", title: "Channels")
                        InfoValue(formattedChannels)
                    }
                    
                    GridRow {
                        InfoLabel(icon: "doc", title: "Format")
                        InfoValue(metadata.fileFormat ?? "Unknown")
                        
                        InfoLabel(icon: "externaldrive", title: "File Size")
                        InfoValue(formattedFileSize)
                    }
                }
            }
            .padding(8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDuration: String {
        guard let duration = metadata.duration else { return "—" }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedBitrate: String {
        guard let bitrate = metadata.bitrate else { return "—" }
        return "\(bitrate) kbps"
    }
    
    private var formattedSampleRate: String {
        guard let sampleRate = metadata.sampleRate else { return "—" }
        
        if sampleRate >= 1000 {
            let khz = Double(sampleRate) / 1000.0
            return String(format: "%.1f kHz", khz)
        } else {
            return "\(sampleRate) Hz"
        }
    }
    
    private var formattedChannels: String {
        guard let channels = metadata.channels else { return "—" }
        
        switch channels {
        case 1:
            return "Mono"
        case 2:
            return "Stereo"
        case 6:
            return "5.1 Surround"
        case 8:
            return "7.1 Surround"
        default:
            return "\(channels) channels"
        }
    }
    
    private var formattedFileSize: String {
        guard let fileSize = metadata.fileSize else { return "—" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

// MARK: - Supporting Views

private struct InfoLabel: View {
    let icon: String
    let title: String
    
    var body: some View {
        Label {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
        }
    }
}

private struct InfoValue: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }
}

#Preview {
    VStack(spacing: 20) {
        TechnicalInfoView(
            metadata: AudioFileMetadata(
                title: "Example Song",
                artist: "Example Artist",
                duration: 245.5,
                bitrate: 320,
                sampleRate: 44100,
                channels: 2,
                fileFormat: "MP3",
                fileSize: 9830400
            )
        )
        
        TechnicalInfoView(
            metadata: AudioFileMetadata(
                title: "High Quality",
                artist: "Artist",
                duration: 180.0,
                bitrate: 1411,
                sampleRate: 96000,
                channels: 6,
                fileFormat: "FLAC",
                fileSize: 31457280
            )
        )
    }
    .padding()
    .frame(width: 600)
}
