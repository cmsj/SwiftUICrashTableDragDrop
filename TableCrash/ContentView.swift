//
//  ContentView.swift
//  TableCrash
//
//  Created by Chris Jones on 28/04/2025.
//

// Instructions to reproduce crash:
// 1. Run app in Xcode
// 2. Click "Create Tree"
// 3. Click "Delete Tree"
// 4. Drag a file from Finder onto the empty table
// 5. App will crash as soon as your mouse enters the table with: Swift/ContiguousArrayBuffer.swift:690: Fatal error: Index out of range

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

struct Node: Identifiable {
    let id: UUID = UUID()
    let name: String
    let thing: String
    let otherThing: String
    var isExpanded: Bool = true

    init(name: String, thing: String, otherThing: String) {
        self.name = name
        self.thing = thing
        self.otherThing = otherThing
    }
}

@Observable
class TableViewModel {
    var nodes: [Node]? = nil

    func createTree() {
        nodes = []
        let child1 = Node(name: "child1", thing: "1", otherThing: "a")
        let child2 = Node(name: "child2", thing: "2", otherThing: "b")
        nodes?.append(child1)
        nodes?.append(child2)
    }

    func deleteTree() {
        nodes = nil
    }

    func processDrop(of: [NSItemProvider]) {
        nodes?.append(Node(name: "\(Int.random(in: 0..<100))", thing: "baz", otherThing: "foo"))
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
                ForEach(viewModel.nodes ?? []) { node in
                    TableRow(node)
                        .dropDestination(for: DropItem.self) { items in
                            // NOTE: If this is enabled, the crash exists
                            print("DisclosureTableRow: .dropDestination")
                            viewModel.processDrop(of: [])
                        }
                }
            }
            .disabled(viewModel.nodes == nil)
            .opacity(viewModel.nodes == nil ? 0.5 : 1)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
