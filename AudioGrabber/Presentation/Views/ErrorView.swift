//
//  ErrorView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
            }
            
            // Error Message
            VStack(spacing: 8) {
                Text("Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Dismiss")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.bordered)
                
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ErrorView(
        message: "Failed to analyze URL. Please check the URL and try again.",
        onRetry: {},
        onDismiss: {}
    )
}
