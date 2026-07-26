//
//  ContentView.swift
//  Fuji
//
//  Created by Arsile on 25/07/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var manager = ContainerManager()
    @State private var selection: Set<String> = []
    @State private var activeTab: String = "containers"
    @State private var selectedContainerIDs: Set<String> = []
    
    var body: some View {
        NavigationSplitView {
            List(selection: $activeTab) {
                Section("Management") {
                    Label("Containers", systemImage: "shippingbox").tag("containers")
                    Label("Images", systemImage: "opticaldisc").tag("images")
                }
            }
            .navigationTitle("Container Manager")
        } detail: {
            Group {
                switch activeTab {
                case "containers":
                    ZStack {
                        ContainerTableView(manager: manager, selection: $selectedContainerIDs)
                        if manager.isLoading {
                            ProgressView {
                                Text("Loading containers...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .controlSize(.large)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        }
                    }
                case "images":
                    ContentUnavailableView(
                        "Images Coming Soon",
                        systemImage: "opticaldisc",
                        description: Text("Run `container image ls --format json`")
                    )
                default:
                    EmptyView()
                }
            }
        }
        .task {
            await manager.refresh()
        }
    }
}

struct ContainerTableView: View {
    @Bindable var manager: ContainerManager
    @Binding var selection: Set<String>
    
    var body: some View {
        Table(manager.containers, selection: $selection) {
            TableColumn("ID") { (item: ContainerItem) in  // ✅ Explicit type
                   Text(item.id.prefix(12))
                       .font(.system(.body, design: .monospaced))
               }
               
               TableColumn("Image") { (item: ContainerItem) in  // ✅ Explicit type
                   Text(item.imageReference)
               }
               
               TableColumn("State") { (item: ContainerItem) in  // ✅ Explicit type
                   Text(item.state.capitalized)
                       .foregroundStyle(item.state == "running" ? .green : .gray)
               }
               
               TableColumn("IP Address") { (item: ContainerItem) in  // ✅ Explicit type
                   Text(item.ipv4Address ?? "—")
                       .font(.system(.body, design: .monospaced))
               }
               
               TableColumn("Memory") { (item: ContainerItem) in  // ✅ Explicit type
                   Text(item.configuration.resources.memoryFormatted)
               }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task { await manager.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(manager.isLoading)
                
                Button {
                    if let id = selection.first {
                        Task { await manager.stopContainer(id: id)}
                    }
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(selection.isEmpty)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
