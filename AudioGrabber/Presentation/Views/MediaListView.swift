//
//  MediaListView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct MediaListView: View {
    @Bindable var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with selection controls
            headerView
            
            Divider()
            
            // Media items list
            if viewModel.mediaItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.mediaItems) { item in
                            MediaItemRow(
                                item: item,
                                isSelected: viewModel.selectedItems.contains(item.id),
                                progress: viewModel.downloadProgress[item.id],
                                onToggle: {
                                    viewModel.toggleSelection(for: item)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // Results count
            HStack(spacing: 4) {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.secondary)
                
                Text("\(viewModel.totalCount) file\(viewModel.totalCount == 1 ? "" : "s") found")
                    .font(.headline)
                
                if viewModel.selectedCount > 0 {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text("\(viewModel.selectedCount) selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Selection buttons
            HStack(spacing: 8) {
                Button("Select All") {
                    viewModel.selectAll()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedCount == viewModel.totalCount)
                
                Button("Deselect All") {
                    viewModel.deselectAll()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedCount == 0)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No audio files found")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MediaListView(viewModel: {
        let vm = MainViewModel()
        vm.mediaItems = [
            MediaItem(
                url: URL(string: "https://example.com/audio1.mp3")!,
                fileName: "audio1.mp3",
                displayName: "Sample Audio 1",
                fileExtension: .mp3,
                fileSize: 5_242_880,
                metadata: MediaMetadata(title: "Sample Audio 1", duration: 245)
            ),
            MediaItem(
                url: URL(string: "https://example.com/audio2.m4a")!,
                fileName: "audio2.m4a",
                displayName: "Sample Audio 2",
                fileExtension: .m4a,
                fileSize: 3_145_728,
                metadata: MediaMetadata(title: "Sample Audio 2", duration: 180)
            )
        ]
        vm.state = .resultsReady
        return vm
    }())
}
