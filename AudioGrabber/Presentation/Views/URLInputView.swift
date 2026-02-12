//
//  URLInputView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct URLInputView: View {
    @Bindable var viewModel: MainViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // URL TextField
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                
                TextField("Enter URL (e.g., https://example.com/audio)", text: $viewModel.urlString)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if viewModel.canAnalyze {
                            Task {
                                await viewModel.analyzeURL()
                            }
                        }
                    }
                    .disabled(viewModel.isAnalyzing || viewModel.isDownloading)
                
                if !viewModel.urlString.isEmpty {
                    Button(action: {
                        viewModel.urlString = ""
                        isTextFieldFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isTextFieldFocused ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            
            // Analyze Button
            Button(action: {
                Task {
                    await viewModel.analyzeURL()
                }
            }) {
                HStack(spacing: 6) {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze")
                }
                .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canAnalyze || viewModel.urlString.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .frame(maxWidth: 700)
    }
}

#Preview {
    URLInputView(viewModel: MainViewModel())
        .padding()
}
