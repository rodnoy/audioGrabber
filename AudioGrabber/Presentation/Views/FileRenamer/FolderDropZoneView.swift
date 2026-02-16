//
//  FolderDropZoneView.swift
//  AudioGrabber
//
//  Drag & drop zone for folder selection in File Renamer.
//  Allows users to drop a folder or select one via file picker.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderDropZoneView: View {
    @ObservedObject var viewModel: FileRenamerViewModel
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isTargeted ? "folder.fill.badge.plus" : "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
                .symbolEffect(.bounce, value: isTargeted)
            
            Text("Перетащите папку сюда")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("или")
                .foregroundColor(.secondary)
            
            Button("Выбрать папку") {
                viewModel.selectFolder()
            }
            .buttonStyle(.borderedProminent)
            
            Text("Будут найдены все аудиофайлы в папке")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
                )
        )
        .padding()
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            // Check if it's a directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                DispatchQueue.main.async {
                    Task {
                        await viewModel.loadFolder(url)
                    }
                }
            }
        }
        
        return true
    }
}

#Preview {
    FolderDropZoneView(viewModel: FileRenamerViewModel())
        .frame(width: 600, height: 400)
}
