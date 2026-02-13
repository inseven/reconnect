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

protocol SidebarContainerViewDelegate: NSObjectProtocol {

    @MainActor
    func sidebarContainerView(_ sidebarContainerView: SidebarContainerView,
                              didSelectSection section: BrowserSection)

}

class SidebarContainerView: NSView {

    class Node: NSObject {

        enum NodeType {
            case header(String)
            case section(BrowserSection)
        }

        @objc dynamic var children: [Node]

        var name: String {
            switch type {
            case .header(let name):
                return name
            case .section(let section):
                return section.title
            }
        }

        var isHeader: Bool {
            switch type {
            case .header:
                return true
            case .section:
                return false
            }
        }

        var section: BrowserSection? {
            guard case .section(let section) = type else {
                return nil
            }
            return section
        }

        let type: NodeType

        private init(type: NodeType, children: [Node] = []) {
            self.type = type
            self.children = children
        }

        convenience init(header: String, children: [Node] = []) {
            self.init(type: .header(header), children: children)
        }

        convenience init(section: BrowserSection, children: [Node] = []) {
            self.init(type: .section(section), children: children)
        }

    }

    class func sidebarNode(from item: Any) -> Node? {
        if let treeNode = item as? NSTreeNode, let node = treeNode.representedObject as? Node {
            return node
        } else {
            return nil
        }
    }

    weak var delegate: SidebarContainerViewDelegate?

    private let scrollView: NSScrollView
    private let outlineView: NSOutlineView
    private let treeController: NSTreeController

    @objc dynamic private var contents: [Node] = []
    private var devices: [DeviceModel] = []  // Shadow state to make managing connected devices easier.

    private var treeControllerObserver: NSKeyValueObservation?

    private var _selectedSection: BrowserSection = .disconnected

    /**
     * Manage the selected section.
     *
     * Sets are guarded ensuring that, if the selection is currently selected, it will not be re-selected. This means
     * that if the currently selected section is not currently visible (e.g., if the tree is collapsed), then it will
     * revealed or the selection shown in the UI. However, if the section is not currently selected, the tree will be
     * expanded and the corresponding node selected.
     */
    var selectedSection: BrowserSection {
        get {
            return _selectedSection
        }
        set {
            dispatchPrecondition(condition: .onQueue(.main))
            guard _selectedSection != newValue else {
                return
            }
            _selectedSection = newValue
            treeController.selectSection(newValue)
        }
    }

    init() {

        scrollView = NSScrollView()
        outlineView = NSOutlineView()
        treeController = NSTreeController()

        super.init(frame: .zero)

        // Configure the scroll view.

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        self.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        scrollView.documentView = outlineView

        // Configure the tree controller.

        treeController.objectClass = Node.self
        treeController.childrenKeyPath = "children"
        treeController.bind(.contentArray, to: self, withKeyPath: "contents")

        contents = [
            Node(header: "Devices", children: [
                Node(section: .disconnected)
            ]),
            Node(header: "Library", children: [
                Node(section: .softwareIndex),
            ]),
        ]
        treeController.content = contents

        // Configure the outline view.

        outlineView.translatesAutoresizingMaskIntoConstraints = false
        outlineView.headerView = nil
        outlineView.focusRingType = .none
        outlineView.delegate = self
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        column.title = "Name"
        column.bind(.value, to: treeController, withKeyPath: "arrangedObjects.name")

        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.bind(.content, to: treeController, withKeyPath: "arrangedObjects")
        outlineView.bind(.selectionIndexPaths, to: treeController, withKeyPath: "selectionIndexPaths")

        // Observe the changes.

        treeControllerObserver = treeController.observe(\.selectedObjects, options: [.new]) { [weak self] (treeController, change) in
            guard
                let self,
                let selectedNode = treeController.selectedNodes.first?.representedObject as? Node,
                case .section(let section) = selectedNode.type
            else {
                return
            }
            DispatchQueue.main.async {
                self.delegate?.sidebarContainerView(self, didSelectSection: section)
            }
        }

        // Start with all the sections expanded.
        outlineView.expandItem(treeController.arrangedObjects.children![0], expandChildren: true)
        outlineView.expandItem(treeController.arrangedObjects.children![1], expandChildren: true)

        // Select the disconnected device item.
        treeController.setSelectionIndexPath(IndexPath(indexes: [0, 0]))

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func view(for identifier: NSUserInterfaceItemIdentifier) -> ConfigurableSidebarCell {

        // This will only return a view if it exists and is available for reuse, instead of creating a new view, as one
        // might have reasonably expected being called `makeView`.
        if let cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? ConfigurableSidebarCell {
            return cellView
        }

        switch identifier {
        case SidebarHeaderCell.identifier:
            return SidebarHeaderCell()
        case SidebarSectionCell.identifier:
            return SidebarSectionCell()
        default:
            fatalError("Unknown cell identifier '\(identifier.rawValue)'.")
        }

    }

}

extension SidebarContainerView: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return Self.sidebarNode(from: item)?.isHeader ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // We use this to allow us to stop header cells from being selected.
        guard let node = Self.sidebarNode(from: item) else {
            return false
        }
        return !node.isHeader
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        dispatchPrecondition(condition: .onQueue(.main))

        // There's a lot going on in this guard statement:
        // - we the node being expanded from the notification
        // - see if that node has an immediate child matching our selected section (returned as an optional index)
        // - get the index path of the node being expanded
        guard
            let node = notification.userInfo?["NSObject"] as? NSTreeNode,
            let selectionIndex = node.children?.firstIndex(where: { ($0.representedObject as? Node)?.section == selectedSection }),
            let parentIndexPath = treeController.arrangedObjects.children?.firstIndexPath(where: { $0 == node })
        else {
            return
        }

        // If we've got here, we know that one of the expanded node's children should be selected, so we assemble the
        // index path for the child node and select it.
        let indexPath = parentIndexPath + [selectionIndex]
        treeController.setSelectionIndexPath(indexPath)
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = Self.sidebarNode(from: item) else {
            return nil
        }
        let view = if self.outlineView(outlineView, isGroupItem: item) {
            view(for: SidebarHeaderCell.identifier)
        } else {
            view(for: SidebarSectionCell.identifier)
        }
        view.configure(node)
        return view
    }

}

extension SidebarContainerView: ApplicationModelConnectionDelegate {

    func applicationModel(_ applicationModel: ApplicationModel, deviceDidConnect deviceModel: DeviceModel) {
        dispatchPrecondition(condition: .onQueue(.main))

        // If `devices` is empty, then we know that this is the first device to connect and we ned to remove the
        // 'Not Connected' sidebar entry.
        if devices.isEmpty {
            treeController.removeObject(atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))
        }

        // Add this device to the list.
        // We should probably track these by id in the future.
        devices.append(deviceModel)

        // Construct and insert the new device entry.
        let drives = deviceModel.drives.map { driveInfo in
            Node(section: .drive(deviceModel.id, driveInfo, deviceModel.platform))
        }
        treeController.insert(Node(section: .device(deviceModel.id, deviceModel.deviceConfiguration.name), children: drives),
                              atArrangedObjectIndexPath: IndexPath(indexes: [0, devices.count - 1]))

        // Select the internal drive.
        selectedSection = .drive(deviceModel.id, deviceModel.internalDrive, deviceModel.platform)
    }
    
    func applicationModel(_ applicationModel: ApplicationModel, deviceDidDisconnect deviceModel: DeviceModel) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Work out the index of the device being removed.
        guard let index = devices.firstIndex(where: { $0.id == deviceModel.id }) else {
            return
        }

        // Remove the device.
        devices.remove(at: index)

        // Remove the existing device entry.
        treeController.removeObject(atArrangedObjectIndexPath: IndexPath(indexes: [0, index]))

        // Insert the disconnected entry if necessary.
        if devices.isEmpty {
            treeController.insert(Node(section: .disconnected),
                                  atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))
        }
    }

}

extension SidebarContainerView: BackupsModelDelegate {

    func backupsModel(_ backupsModel: BackupsModel, didUpdateBackupSets backupSets: [BackupSet]) {
        dispatchPrecondition(condition: .onQueue(.main))
        let children = backupSets
            .sorted { lhs, rhs in
                return lhs.device.name.localizedCaseInsensitiveCompare(rhs.device.name) == .orderedAscending
            }
            .map { backupSet in
                let children: [Node] = backupSet.backups
                    .sorted { lhs, rhs in
                        return lhs.manifest.date > rhs.manifest.date
                    }
                    .map { backup in
                        return Node(section: .backup(backup))
                    }
                return Node(section: .backupSet(backupSet.device), children: children)
            }
        let selection = treeController.selectionIndexPath  // Read the current selection so we can restore it later.
        let node = Node(header: "Backups", children: children)
        if (treeController.arrangedObjects.children?.count ?? 0) > 2 {
            treeController.removeObject(atArrangedObjectIndexPath: IndexPath(indexes: [2]))
        }
        treeController.insert(node, atArrangedObjectIndexPath: IndexPath(indexes: [2]))
        outlineView.expandItem(treeController.arrangedObjects.children![2], expandChildren: true)
        treeController.setSelectionIndexPath(selection)  // Restore selection.
    }

}
