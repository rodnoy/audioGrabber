//
//  AudioGrabberApp.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

@main
struct AudioGrabberApp: App {
    @State private var viewModel = MainViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
