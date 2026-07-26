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

import AppKit
import SwiftUI

class SidebarSectionCell: NSTableCellView, ConfigurableSidebarCell {

    struct LayoutMetrics {
        static let horizontalMargin: CGFloat = 5.0
    }

    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "SidebarSectionCell")

    private var hostingView: NSHostingView<SectionLabel>?

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.identifier = Self.identifier

        let imageView = NSImageView()
        addSubview(imageView)
        self.imageView = imageView

        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.lineBreakMode = .byTruncatingMiddle
        addSubview(textField)
        self.textField = textField
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(applicationModel: ApplicationModel, node: SidebarContainerView.Node) {
        guard case .section(let section) = node.type else {
            fatalError("Unsupported node type \(node.type).")
        }
        host(SectionLabel(applicationModel: applicationModel, section: section))
    }

    private func host(_ content: SectionLabel) {
        if let hostingView = hostingView {
            hostingView.rootView = content
        } else {
            let newHostingView = NSHostingView(rootView: content)
            newHostingView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(newHostingView)
            setupConstraints(for: newHostingView)
            self.hostingView = newHostingView
        }
    }

    func setupConstraints(for view: NSView) {
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: LayoutMetrics.horizontalMargin),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -LayoutMetrics.horizontalMargin),
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

}
