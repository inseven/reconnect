// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2026 Jason Morley
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

import SwiftUI

import ReconnectCore

struct DirectoryView: View {

    @State private var directoryModel: DirectoryModel
    @State private var isTargeted = false

    private var applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel,
         transfersModel: TransfersModel,
         navigationModel: NavigationModel,
         deviceModel: DeviceModel,
         driveInfo: FileServer.DriveInfo,
         path: String) {
        self.applicationModel = applicationModel
        _directoryModel = State(initialValue: DirectoryModel(applicationModel: applicationModel,
                                                             transfersModel: transfersModel,
                                                             navigationModel: navigationModel,
                                                             deviceModel: deviceModel,
                                                             driveInfo: driveInfo,
                                                             path: path))

    }

    func itemProvider(for file: FileServer.DirectoryEntry) -> NSItemProvider? {
        dispatchPrecondition(condition: .onQueue(.main))
        let convertDraggedFiles = applicationModel.convertDraggedFiles
        let provider = NSItemProvider()
        provider.suggestedName = if convertDraggedFiles {
            FileConverter.targetFilename(for: file)
        } else {
            file.name
        }
        provider.registerFileRepresentation(for: file.isDirectory ? .folder : .data) { completion in
            DispatchQueue.main.async {
                do {
                    let fileManager = FileManager.default
                    let temporaryDirectoryURL = try fileManager.createTemporaryDirectory()
                    self.directoryModel.download(Set([file.id]),
                                                 to: temporaryDirectoryURL,
                                                 convertFiles: convertDraggedFiles) { result in
                        switch result {
                        case .success(let urls):
                            completion(urls.first!, false, nil)
                        case .failure(let error):
                            completion(nil, false, error)
                        }
                        try? fileManager.removeItemLoggingErrors(at: temporaryDirectoryURL)
                    }
                } catch {
                    print("Failed to download dragged file with error \(error).")
                    completion(nil, false, error)
                }
            }
            return nil
        }
        return provider
    }

    var body: some View {
        @Bindable var directoryModel = directoryModel
        ZStack {
            Table(of: FileServer.DirectoryEntry.self, selection: $directoryModel.fileSelection) {
                TableColumn("") { file in
                    Image(file.fileType.image)
                }
                .width(16.0)
                TableColumn("Name") { file in
                    EditableText(initialValue: file.name) { text in
                        directoryModel.rename(file: file, to: text)
                    }
                }
                TableColumn("Date Modified") { file in
                    Text(file.modificationDate.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                TableColumn("Size") { file in
                    if file.isDirectory {
                        Text("--")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(file.size.formatted(.byteCount(style: .file)))
                            .foregroundStyle(.secondary)
                    }
                }
                TableColumn("Type") { file in
                    FileTypePopover(file: file)
                        .foregroundStyle(.secondary)
                }
            } rows: {
                ForEach(directoryModel.files) { file in
                    TableRow(file)
                        .itemProvider {
                            itemProvider(for: file)
                        }
                }
            }
            .onKeyPress { keyPress in
                if keyPress.key == .downArrow && keyPress.modifiers.contains(.command) {
                    directoryModel.openSelection()
                    return .handled
                }
                return .ignored
            }
            .contextMenu(forSelectionType: FileServer.DirectoryEntry.ID.self) { items in

                Button("Open", systemImage: "arrow.up.forward.square") {
                    directoryModel.navigate(to: items.first!)
                }
                .disabled(items.count != 1 || !(items.first?.isWindowsDirectory ?? false))

                Divider()

                Button("Download", systemImage: "display.and.arrow.down") {
                    directoryModel.download(items,
                                          to: FileManager.default.downloadsDirectory,
                                          convertFiles: applicationModel.convertFiles,
                                          completion: { _ in })
                }
                .disabled(items.count < 1)

                Divider()

                Button("Delete", systemImage: "trash") {
                    directoryModel.delete(items)
                }
                .disabled(items.count < 1)

            } primaryAction: { items in
                guard
                    items.count == 1,
                    let item = items.first,
                    item.isWindowsDirectory
                else {
                    return
                }
                directoryModel.navigate(to: item)
            }
            .onDeleteCommand {
                directoryModel.delete()
            }
            .contextMenu {
                Button("New Folder") {
                    directoryModel.createNewFolder()
                }
            }
            if isTargeted {
                Rectangle()
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else {
                        return
                    }
                    DispatchQueue.main.sync {
                        directoryModel.upload(url: url)
                    }
                }
            }
            return true
        }
        .navigationTitle(directoryModel.navigationTitle ?? "My Psion")
        .presents($directoryModel.lastError)
        .task {
            await directoryModel.start()
        }
        .showsDeviceProgress()
        .focusedSceneObject(FileManageableProxy(directoryModel))
        .focusedSceneObject(ParentNavigableProxy(directoryModel))
        .focusedSceneObject(RefreshableProxy(directoryModel))
    }

}
