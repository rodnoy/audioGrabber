//
//  RenameListHeaderView.swift
//  AudioGrabber
//
//  Header view displaying folder path, statistics, and select all toggle.
//

import SwiftUI

struct RenameListHeaderView: View {
    @ObservedObject var viewModel: FileRenamerViewModel
    
    var body: some View {
        HStack {
            // Путь к папке
            if let url = viewModel.selectedFolderURL {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .help(url.path)
            }
            
            Spacer()
            
            // Статистика
            HStack(spacing: 16) {
                Label("\(viewModel.totalCount)", systemImage: "doc.fill")
                    .help("Всего файлов")
                
                Label("\(viewModel.readyToRenameCount)", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .help("Готовы к переименованию")
                
                if viewModel.noTitleCount > 0 {
                    Label("\(viewModel.noTitleCount)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .help("Без метаданных title")
                }
            }
            .font(.subheadline)
            
            Divider()
                .frame(height: 20)
            
            // Кнопка выбрать все
            Toggle("Выбрать все", isOn: Binding(
                get: { viewModel.allSelected },
                set: { viewModel.toggleSelectAll($0) }
            ))
            .toggleStyle(.checkbox)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    VStack(spacing: 0) {
        RenameListHeaderView(viewModel: {
            let vm = FileRenamerViewModel()
            // Mock data for preview
            return vm
        }())
        
        Divider()
        
        Color.gray.opacity(0.1)
    }
    .frame(width: 700, height: 300)
}
