//
//  DownloadControlsView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct DownloadControlsView: View {
    @Bindable var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Overall progress bar (shown during download)
            if viewModel.isDownloading {
                overallProgressView
            }
            
            // Controls
            HStack(spacing: 12) {
                // Download directory selection
                directorySelectionView
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Subviews
    
    private var directorySelectionView: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            
            if let directory = viewModel.downloadDirectory {
                Text(directory.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                    .frame(maxWidth: 200, alignment: .leading)
            } else {
                Text("No download location selected")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button("Choose...") {
                viewModel.chooseDownloadDirectory()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isDownloading)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isDownloading {
            // Cancel button during download
            Button(action: {
                viewModel.cancelDownloads()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel")
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
        } else if viewModel.state == .completed {
            // Reset button after completion
            Button(action: {
                viewModel.reset()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Start Over")
                }
            }
            .buttonStyle(.bordered)
        } else if viewModel.state == .resultsReady {
            // Download button
            Button(action: {
                Task {
                    await viewModel.downloadSelected()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Download Selected (\(viewModel.selectedCount))")
                }
                .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canDownload)
        }
    }
    
    private var overallProgressView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Downloading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            ProgressView(value: viewModel.overallProgress, total: 1.0)
                .progressViewStyle(.linear)
        }
    }
}

#Preview("Ready to Download") {
    DownloadControlsView(viewModel: {
        let vm = MainViewModel()
        vm.state = .resultsReady
        vm.selectedItems = [UUID(), UUID()]
        vm.downloadDirectory = URL(fileURLWithPath: "/Users/test/Downloads")
        return vm
    }())
}

#Preview("Downloading") {
    DownloadControlsView(viewModel: {
        let vm = MainViewModel()
        vm.state = .downloading
        vm.downloadProgress = [UUID(): 0.3, UUID(): 0.7]
        vm.downloadDirectory = URL(fileURLWithPath: "/Users/test/Downloads")
        return vm
    }())
}

#Preview("Completed") {
    DownloadControlsView(viewModel: {
        let vm = MainViewModel()
        vm.state = .completed
        vm.downloadDirectory = URL(fileURLWithPath: "/Users/test/Downloads")
        return vm
    }())
}
