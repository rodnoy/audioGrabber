//
//  RenameControlsView.swift
//  AudioGrabber
//
//  Control buttons for managing the rename process.
//

import SwiftUI

struct RenameControlsView: View {
    @ObservedObject var viewModel: FileRenamerViewModel
    
    var body: some View {
        HStack {
            // Кнопка очистить
            Button(action: { viewModel.clearItems() }) {
                Label("Очистить", systemImage: "trash")
            }
            .help("Очистить список файлов")
            
            // Кнопка выбрать другую папку
            Button(action: { viewModel.selectFolder() }) {
                Label("Другая папка", systemImage: "folder")
            }
            .help("Выбрать другую папку")
            
            Spacer()
            
            // Прогресс
            if viewModel.isRenaming {
                HStack(spacing: 8) {
                    ProgressView(value: viewModel.renameProgress)
                        .frame(width: 100)
                    
                    Text("\(Int(viewModel.renameProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            // Кнопка переименовать
            Button(action: {
                Task {
                    await viewModel.renameSelectedFiles()
                }
            }) {
                Label("Переименовать (\(viewModel.selectedCount))", systemImage: "pencil")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedCount == 0 || viewModel.isRenaming)
            .help(viewModel.selectedCount == 0 ? "Выберите файлы для переименования" : "Переименовать выбранные файлы")
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    VStack(spacing: 0) {
        Color.gray.opacity(0.1)
        
        Divider()
        
        RenameControlsView(viewModel: {
            let vm = FileRenamerViewModel()
            // Mock data for preview
            return vm
        }())
    }
    .frame(width: 700, height: 300)
}
