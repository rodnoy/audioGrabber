//
//  ContentView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel? = nil) {
        let vm = viewModel ?? MainViewModel()
        self._viewModel = State(initialValue: vm)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main Content
            mainContent
            
            Divider()
            
            // Footer with download controls
            DownloadControlsView(viewModel: viewModel)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("AudioGrabber")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            URLInputView(viewModel: viewModel)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .idle:
            idleView
            
        case .analyzing:
            analyzingView
            
        case .resultsReady, .downloading, .completed:
            MediaListView(viewModel: viewModel)
            
        case .error:
            ErrorView(
                message: viewModel.errorMessage ?? "An unknown error occurred",
                onRetry: {
                    Task {
                        await viewModel.analyzeURL()
                    }
                },
                onDismiss: {
                    viewModel.reset()
                }
            )
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Enter a URL to find audio files")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Paste a URL above and click Analyze to get started")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var analyzingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing URL...")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Searching for audio files")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
