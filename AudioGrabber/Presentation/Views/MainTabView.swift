//
//  MainTabView.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

/// Main container view with tab navigation for the application
struct MainTabView: View {
    enum Tab {
        case downloader
        case metadataEditor
        case fileRenamer
    }
    
    @State private var selectedTab: Tab = .downloader
    private let metadataService: MetadataServiceProtocol
    
    init() {
        self.metadataService = SwiftTaggerService()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Audio Downloader (existing ContentView)
            ContentView()
                .tabItem {
                    Label("Downloader", systemImage: "arrow.down.circle")
                }
                .tag(Tab.downloader)
            
            // Tab 2: Metadata Editor
            MetadataEditorView(metadataService: metadataService)
                .tabItem {
                    Label("Metadata Editor", systemImage: "tag")
                }
                .tag(Tab.metadataEditor)
            
            // Tab 3: File Renamer
            FileRenamerView()
                .tabItem {
                    Label("File Renamer", systemImage: "pencil.and.list.clipboard")
                }
                .tag(Tab.fileRenamer)
        }
    }
}

#Preview {
    MainTabView()
}
