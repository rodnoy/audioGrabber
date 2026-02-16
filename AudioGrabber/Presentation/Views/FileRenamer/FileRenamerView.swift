//
//  FileRenamerView.swift
//  AudioGrabber
//
//  Main container view for the File Renamer feature.
//  Displays either a drop zone for folder selection or the rename interface.
//

import SwiftUI

struct FileRenamerView: View {
    @StateObject private var viewModel = FileRenamerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.items.isEmpty {
                FolderDropZoneView(viewModel: viewModel)
            } else {
                // Заголовок со статистикой
                RenameListHeaderView(viewModel: viewModel)
                
                Divider()
                
                // Список файлов
                RenameFileListView(viewModel: viewModel)
                
                Divider()
                
                // Кнопки управления
                RenameControlsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    FileRenamerView()
}
