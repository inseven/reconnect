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

protocol SidebarOutlineViewContainerViewDelegate: NSObjectProtocol {

    @MainActor
    func sidebarOutlineVieContainer(_ sidebarOutlineVieContainer: SidebarOutlineViewContainerView,
                                    didSelecSection section: BrowserSection)

}

class SidebarOutlineViewContainerView: NSView {

    class func sidebarNode(from item: Any) -> SidebarNode? {
        if let treeNode = item as? NSTreeNode, let node = treeNode.representedObject as? SidebarNode {
            return node
        } else {
            return nil
        }
    }

    weak var delegate: SidebarOutlineViewContainerViewDelegate?

    private let scrollView: NSScrollView
    private let outlineView: NSOutlineView
    private let treeController: NSTreeController

    private var treeControllerObserver: NSKeyValueObservation?

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
        scrollView.focusRingType = .none

        self.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        scrollView.documentView = outlineView

        // Configure the tree controller.

        treeController.objectClass = SidebarNode.self
        treeController.childrenKeyPath = "children"
        treeController.content = [
            SidebarNode(header: "Devices", children: [
                SidebarNode(section: .disconnected)
            ]),
            SidebarNode(header: "Library", children: [
                SidebarNode(section: .softwareIndex),
            ]),
        ]

        // Configure the outline view.

        outlineView.translatesAutoresizingMaskIntoConstraints = false
        outlineView.headerView = nil
        outlineView.focusRingType = .none
        outlineView.delegate = self
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        column.title = "Name"
        column.width = 200  // TODO: This feels messy?
        column.bind(.value, to: treeController, withKeyPath: "arrangedObjects.name")

        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.bind(.content, to: treeController, withKeyPath: "arrangedObjects")
        outlineView.bind(.selectionIndexPaths, to: treeController, withKeyPath: "selectionIndexPaths")

        // Observe the changes.

        treeControllerObserver = treeController.observe(\.selectedObjects, options: [.new]) { [weak self] (treeController, change) in
            guard
                let self,
                let selectedNode = treeController.selectedNodes.first?.representedObject as? SidebarNode,
                case .item(let section) = selectedNode.type
            else {
                return
            }
            DispatchQueue.main.async {
                self.delegate?.sidebarOutlineVieContainer(self, didSelecSection: section)
            }
        }

        // Start with all the sections expanded.
        outlineView.expandItem(treeController.arrangedObjects.children![0], expandChildren: true)
        outlineView.expandItem(treeController.arrangedObjects.children![1], expandChildren: true)

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
        case SidebarItemCell.identifier:
            return SidebarItemCell()
        default:
            fatalError("Unknown cell identifier '\(identifier.rawValue)'.")
        }

    }

}

extension SidebarOutlineViewContainerView: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return Self.sidebarNode(from: item)?.isGroup ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // We use this to allow us to stop header cells from being selected.
        guard let node = Self.sidebarNode(from: item) else {
            return false
        }
        return !node.isGroup
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        // TODO: Use this instead of tracking the treeController.
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        // TODO: Can reselect here.
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = Self.sidebarNode(from: item) else {
            return nil
        }
        let view = if self.outlineView(outlineView, isGroupItem: item) {
            view(for: SidebarHeaderCell.identifier)
        } else {
            view(for: SidebarItemCell.identifier)
        }
        view.configure(node)
        return view
    }

}

extension SidebarOutlineViewContainerView: ApplicationModelDelegate {

    // N.B. This implementation assumes that we'll get matched connections and disconnections for single devices.
    // It will need to be updated in the future if we grow support for multiple connected devices.

    func deviceDidConnect(deviceModel: DeviceModel) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Remove the disconnected entry.
        treeController.removeObject(atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))

        // Construct and insert the new device entry.
        let drives = deviceModel.drives.map { driveInfo in
            SidebarNode(section: .drive(deviceModel.id, driveInfo))
        }
        treeController.insert(SidebarNode(section: .device(deviceModel.id), children: drives),
                              atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))

        // Select the new device if the current selection is in the devices section.
        let index = deviceModel.drives.firstIndex { $0.mediaType == .ram }
        if let index {
            treeController.setSelectionIndexPath(IndexPath(indexes: [0, 0, index]))
        }
    }
    
    func deviceDidDisconnect(deviceModel: DeviceModel) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Remove the existing device entry.
        treeController.removeObject(atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))

        // Insert the disconnected entry.
        treeController.insert(SidebarNode(section: .disconnected),
                              atArrangedObjectIndexPath: IndexPath(indexes: [0, 0]))

        // TODO: Something is causing the selection to change here even though we're not actively doing it. I think.

    }

    func sectionDidChange(section newSection: BrowserSection) {
        dispatchPrecondition(condition: .onQueue(.main))

        treeController.selectFirstIndexPath { node in
            guard let node = node.representedObject as? SidebarNode,
                  case .item(let section) = node.type
            else {
                return false
            }
            return section == newSection
        }
    }

}

extension NSTreeController {

    func firstIndexPath(`where` predicate: (NSTreeNode) -> Bool) -> IndexPath? {
        return arrangedObjects.children?.firstIndexPath(where: predicate)
    }

    func selectFirstIndexPath(`where` predicate: (NSTreeNode) -> Bool) {
        guard
            let indexPath = arrangedObjects.children?.firstIndexPath(where: predicate),
            selectionIndexPath != indexPath
        else {
            return
        }
        setSelectionIndexPath(indexPath)
    }

}

extension Array where Element == NSTreeNode {

    // Find the first index path matching the predicate using a depth first search.
    func firstIndexPath(`where` predicate: (NSTreeNode) -> Bool) -> IndexPath? {
        for child in enumerated() {
            if predicate(child.element) {
                return IndexPath(index: child.offset)
            }
            if let children = child.element.children,
               let indexPath = children.firstIndexPath(where: predicate) {
                return IndexPath(index: child.offset) + indexPath
            }
        }
        return nil
    }

}
