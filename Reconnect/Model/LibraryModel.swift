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

import Combine
import Foundation
import SwiftUI

import ReconnectCore

/// Callbacks always occur on `MainActor`.
protocol LibraryModelDelegate: AnyObject {

    @MainActor
    func libraryModelDidCancel(libraryModel: LibraryModel)

    @MainActor
    func libraryModel(libraryModel: LibraryModel, didSelectItem item: LibraryModel.Item)

}

@MainActor class LibraryModel: ObservableObject {

    public struct Item {

        public let sourceURL: URL
        public let url: URL

    }

    @Published var isLoading: Bool = true
    @Published var programs: [Program] = []
    @Published var searchFilter: String = ""
    @Published var filteredPrograms: [Program] = []
    @Published var error: Error? = nil

    weak var delegate: LibraryModelDelegate?

    private var cancellables: Set<AnyCancellable> = []

    @Published var downloads: [URL: URLSessionDownloadTask] = [:]

    private var isRunning: Bool = false

    init() {
    }

    @MainActor func start() {
        guard !isRunning else {
            return
        }
        isRunning = true
        $programs
            .combineLatest($searchFilter)
            .map { programs, filter in
               return programs.filter { filter.isEmpty || $0.name.localizedStandardContains(filter) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredPrograms, on: self)
            .store(in: &cancellables)
        Task {
            await self.fetch()
        }
    }

    @MainActor private func fetch() async {
        isLoading = true
        let url = URL.softwareIndexAPIV1.appendingPathComponent("programs")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()

            // Filter the list to include only SIS files.
            let programs = try decoder.decode([Program].self, from: data).compactMap { program -> Program? in
                let versions: [Version] = program.versions.compactMap { version in
                    let variants: [Collection] = version.variants.compactMap { collection in
                        let items: [Release] = collection.items.compactMap { release -> Release? in
                            guard release.kind == .installer else {
                                return nil
                            }
                            return release
                        }
                        guard let release = items.first else {
                            return nil
                        }
                        return Collection(identifier: collection.identifier, items: [release])
                    }
                    guard variants.count > 0 else {
                        return nil
                    }
                    return Version(version: version.version, variants: variants)
                }
                guard versions.count > 0 else {
                    return nil
                }
                return Program(id: program.id,
                               name: program.name,
                               icon: program.icon,
                               versions: versions,
                               subtitle: program.subtitle,
                               description: program.description,
                               tags: program.tags,
                               screenshots: program.screenshots)
            }.sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            await MainActor.run {
                self.isLoading = false
                self.programs = programs
            }
        } catch {
            self.isLoading = false
            print("Failed to fetch data with error \(error).")
        }
    }

    func download(_ release: Release) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Ensure there are no active downloads for that URL.
        guard downloads[release.downloadURL] == nil else {
            return
        }

        let downloadURL = release.downloadURL

        // Create the download task.
        let downloadTask = URLSession.shared.downloadTask(with: downloadURL) { [weak self] url, response, error in
            dispatchPrecondition(condition: .notOnQueue(.main))
            guard let self else {
                return
            }
            do {
                // First, cean up the download task and observation.
                DispatchQueue.main.sync {
                    _ = self.downloads.removeValue(forKey: downloadURL)
                }

                // Check for errors.
                guard let url else {
                    throw error ?? ReconnectError.unknownDownloadFailure
                }

                // Create a temporary directory and move the downloaded contents to ensure it has the correct filename.
                let fileManager = FileManager.default
                let temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent((UUID().uuidString))
                try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
                let itemURL = temporaryDirectory.appendingPathComponent(release.filename)
                try fileManager.moveItem(at: url, to: itemURL)

                // Call our delegate.
                let item = Item(sourceURL: downloadURL, url: itemURL)
                DispatchQueue.main.async {
                    self.delegate?.libraryModel(libraryModel: self, didSelectItem: item)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }

        // Cache the download task.
        self.downloads[downloadURL] = downloadTask

        // Start the download.
        downloadTask.resume()
    }

}

extension LibraryModel: Refreshable {

    var canRefresh: Bool {
        return !self.isLoading
    }
    
    var isRefreshing: Bool {
        return self.isLoading
    }
    
    func refresh() {
        Task {
            await fetch()
        }
    }
    
}
