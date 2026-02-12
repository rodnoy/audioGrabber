//
//  MediaItemRow.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct MediaItemRow: View {
    let item: MediaItem
    let isSelected: Bool
    let progress: Double?
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Format Icon
            formatIcon
                .frame(width: 32, height: 32)
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Format Badge
                    Text(item.fileExtension.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(formatColor.opacity(0.2))
                        .foregroundStyle(formatColor)
                        .cornerRadius(4)
                    
                    // File Size
                    if let size = item.fileSize {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(formatFileSize(size))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Duration
                    if let duration = item.duration {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Progress or Status
            if let progress = progress {
                progressView(progress)
            } else {
                statusIcon
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    // MARK: - Subviews
    
    private var formatIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(formatColor.opacity(0.2))
            
            Image(systemName: formatIconName)
                .font(.system(size: 16))
                .foregroundStyle(formatColor)
        }
    }
    
    private var statusIcon: some View {
        Image(systemName: "arrow.down.circle")
            .font(.title3)
            .foregroundStyle(.secondary)
    }
    
    private func progressView(_ progress: Double) -> some View {
        HStack(spacing: 8) {
            ProgressView(value: progress, total: 1.0)
                .frame(width: 80)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formatColor: Color {
        switch item.fileExtension {
        case .mp3:
            return .blue
        case .m4a, .aac:
            return .purple
        case .wav:
            return .green
        case .flac:
            return .orange
        case .ogg:
            return .pink
        case .opus:
            return .indigo
        }
    }
    
    private var formatIconName: String {
        switch item.fileExtension {
        case .mp3, .m4a, .aac, .wav, .flac, .ogg, .opus:
            return "waveform"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        MediaItemRow(
            item: MediaItem(
                url: URL(string: "https://example.com/audio.mp3")!,
                fileName: "audio.mp3",
                displayName: "Sample Audio File",
                fileExtension: .mp3,
                fileSize: 5_242_880,
                metadata: MediaMetadata(title: "Sample Audio File", duration: 245)
            ),
            isSelected: false,
            progress: nil,
            onToggle: {}
        )
        
        MediaItemRow(
            item: MediaItem(
                url: URL(string: "https://example.com/audio.m4a")!,
                fileName: "audio.m4a",
                displayName: "Another Audio File",
                fileExtension: .m4a,
                fileSize: 3_145_728,
                metadata: MediaMetadata(title: "Another Audio File", duration: 180)
            ),
            isSelected: true,
            progress: 0.65,
            onToggle: {}
        )
    }
    .padding()
}
