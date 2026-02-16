//
//  RenameFileRow.swift
//  AudioGrabber
//
//  Individual row displaying file rename information with status indicators.
//

import SwiftUI

struct RenameFileRow: View {
    let item: RenameItem
    @ObservedObject var viewModel: FileRenamerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox (только для файлов с title)
            if item.canBeRenamed {
                Toggle("", isOn: Binding(
                    get: { item.isSelected },
                    set: { _ in viewModel.toggleSelection(for: item) }
                ))
                .toggleStyle(.checkbox)
                .help("Выбрать для переименования")
            } else {
                // Красный треугольник для файлов без title
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help("Нет метаданных title")
            }
            
            // Иконка статуса
            statusIcon
            
            // Старое имя
            VStack(alignment: .leading, spacing: 2) {
                Text("Было:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.originalName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Стрелка
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            // Новое имя
            VStack(alignment: .leading, spacing: 2) {
                Text("Станет:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.displayNewName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(item.newName == nil ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .opacity(item.status == .renamed ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
                .help("Ожидает переименования")
        case .noTitle:
            Image(systemName: "minus.circle")
                .foregroundColor(.orange)
                .help("Нет метаданных title")
        case .renamed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .help("Успешно переименован")
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .help("Ошибка переименования")
        case .skipped:
            Image(systemName: "forward.circle")
                .foregroundColor(.secondary)
                .help("Пропущен")
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        // Pending file with title
        RenameFileRow(
            item: RenameItem(
                id: UUID(),
                originalURL: URL(fileURLWithPath: "/test/old_file.mp3"),
                originalName: "old_file",
                fileExtension: "mp3",
                newName: "New Song Title",
                isSelected: true,
                status: .pending
            ),
            viewModel: FileRenamerViewModel()
        )
        
        // File without title
        RenameFileRow(
            item: RenameItem(
                id: UUID(),
                originalURL: URL(fileURLWithPath: "/test/no_title.mp3"),
                originalName: "no_title",
                fileExtension: "mp3",
                newName: nil,
                isSelected: false,
                status: .noTitle
            ),
            viewModel: FileRenamerViewModel()
        )
        
        // Renamed file
        RenameFileRow(
            item: RenameItem(
                id: UUID(),
                originalURL: URL(fileURLWithPath: "/test/renamed.mp3"),
                originalName: "old_name",
                fileExtension: "mp3",
                newName: "Renamed Song",
                isSelected: false,
                status: .renamed
            ),
            viewModel: FileRenamerViewModel()
        )
        
        // Failed file
        RenameFileRow(
            item: RenameItem(
                id: UUID(),
                originalURL: URL(fileURLWithPath: "/test/failed.mp3"),
                originalName: "failed",
                fileExtension: "mp3",
                newName: "Should Be This",
                isSelected: false,
                status: .failed("Permission denied")
            ),
            viewModel: FileRenamerViewModel()
        )
    }
    .padding()
    .frame(width: 700)
}
