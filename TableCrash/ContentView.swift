//
//  ContentView.swift
//  TableCrash
//
//  Created by Chris Jones on 28/04/2025.
//

// Instructions to reproduce crash:
// 1. Run app in Xcode
// 2. Click "Create Tree"
// 3. Drag a file from Finder onto the root node of the tree
// 4. Click "Delete Tree"
// 5. Drag a file from Finder onto the empty table
// 6. App will crash as soon as your mouse enters the table with: Swift/ContiguousArrayBuffer.swift:690: Fatal error: Index out of range

// NOTE: You can also comment out the .dropDestination, uncomment .onInsert and reproduce the same way

import SwiftUI

enum DropItem: Codable, Transferable {
    case none
    case file(URL)

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { DropItem.file($0) }
    }

    var file: URL? {
        switch self {
        case .file(let url): return url
        default: return nil
        }
    }
}

@Observable
class Node: Identifiable {
    let id: UUID = UUID()
    let name: String
    let thing: String
    let otherThing: String
    var children: [Node]? = nil
    var isExpanded: Bool = true

    init(name: String, thing: String, otherThing: String) {
        self.name = name
        self.thing = thing
        self.otherThing = otherThing
    }

    func enableChildren() {
        if children == nil {
            children = []
        }
    }
}

@Observable
class Tree {
    var root: Node

    init() {
        root = Node(name: "root", thing: "1", otherThing: "a")
        root.enableChildren()

        let child = Node(name: "child", thing: "2", otherThing: "b")
        child.enableChildren()
        root.children?.append(child)
    }
}

@Observable
class TableViewModel {
    var tree: Tree? = nil

    func createTree() {
        tree = Tree()
    }

    func deleteTree() {
        tree = nil
    }

    func processDrop(of: [NSItemProvider]) {
        tree?.root.children?.append(Node(name: "\(Int.random(in: 0..<100))", thing: "baz", otherThing: "foo"))
    }
}

struct TableRowTreeContent: TableRowContent {
    let node: Node?
    let viewModel: TableViewModel

    var tableRowBody: some TableRowContent<Node> {
        ForEach(node?.children ?? []) { child in
            if let _ = child.children {
                @Bindable var child = child
                DisclosureTableRow(child, isExpanded: $child.isExpanded) {
                    TableRowTreeContent(node: child, viewModel: viewModel)
                }
                // NOTE: If this is present at all, the crash exists
                .dropDestination(for: DropItem.self) { items in
                    // NOTE: If this is enabled, the crash exists
                    print("DisclosureTableRow: .dropDestination")
                    viewModel.processDrop(of: [])
                }
            } else {
                TableRow(child)
            }
        }
        // NOTE: If this is present at all, the crash exists
//        .onInsert(of: [.data]) { index, providers in
//            // NOTE: If this is enabled, the crash exists
//            print("TableRowTreeContent: .onInsert")
//            viewModel.processDrop(of: [])
//        }
    }
}

struct ContentView: View {
    @State private var viewModel = TableViewModel()
    var body: some View {
        VStack {
            HStack {
                Button("Create Tree") {
                    viewModel.createTree()
                }
                Button("Delete Tree") {
                    viewModel.deleteTree()
                }
            }
            Table(of: Node.self) {
                TableColumn("UUID", value: \.id.uuidString)
                TableColumn("Name", value: \.name)
                TableColumn("Thing", value: \.thing)
                TableColumn("Other Thing", value: \.otherThing)
            } rows: {
                TableRowTreeContent(node: viewModel.tree?.root, viewModel: viewModel)
            }
            .disabled(viewModel.tree == nil)
            .opacity(viewModel.tree == nil ? 0.5 : 1)
            // NOTE: Unclear if this relates to the crash
//            .onDrop(of: [.fileURL], isTargeted: nil, perform: { items, _ in
//                print("Table: onDrop")
//                guard viewModel.tree != nil else {
//                    print("No tree yet")
//                    return false
//                }
//                viewModel.processDrop(of: items)
//                return true
//            })
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
