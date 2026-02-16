//
//  RenameFileListView.swift
//  AudioGrabber
//
//  List view displaying all files to be renamed.
//

import SwiftUI

struct RenameFileListView: View {
    @ObservedObject var viewModel: FileRenamerViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                RenameFileRow(item: item, viewModel: viewModel)
            }
        }
        .listStyle(.inset)
    }
}

#Preview {
    RenameFileListView(viewModel: FileRenamerViewModel())
        .frame(width: 700, height: 400)
}
