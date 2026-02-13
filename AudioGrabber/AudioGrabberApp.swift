//
//  AudioGrabberApp.swift
//  AudioGrabber
//
//  Created on 2026-02-12.
//

import SwiftUI

@main
struct AudioGrabberApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
