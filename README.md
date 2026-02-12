# AudioGrabber

macOS application for downloading audio files from web pages.

## Project Structure

```
AudioGrabber/
├── AudioGrabber.xcodeproj/     # Xcode project configuration
├── AudioGrabber/               # Main application source
│   ├── AudioGrabberApp.swift   # SwiftUI app entry point
│   ├── Info.plist              # App configuration
│   ├── AudioGrabber.entitlements # Security entitlements
│   ├── Assets.xcassets/        # App assets and icons
│   ├── Domain/                 # Business logic layer
│   │   ├── Protocols/          # Protocol definitions
│   │   └── Models/             # Domain models
│   ├── Data/                   # Data layer
│   │   ├── Parsers/            # HTML parsing logic
│   │   └── Services/           # Network and download services
│   └── Presentation/           # UI layer
│       ├── Views/              # SwiftUI views
│       └── ViewModels/         # View models
```

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

The project follows Clean Architecture principles with three main layers:

1. **Domain Layer**: Contains business logic, protocols, and models
2. **Data Layer**: Implements data fetching, parsing, and storage
3. **Presentation Layer**: SwiftUI views and view models

For detailed architecture documentation, see [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).

## Getting Started

1. Open `AudioGrabber.xcodeproj` in Xcode
2. Select the AudioGrabber scheme
3. Build and run (⌘R)

## Bundle Identifier

`com.storyteller.audiograbber`

## Entitlements

- App Sandbox: Enabled
- Network Client: Enabled (for downloading web content)
- User Selected Files: Read/Write (for saving downloaded files)

## License

Copyright © 2026 Storyteller. All rights reserved.
