//
//  ContentView.swift
//  devtools
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var activeTabs: [TabInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            List(activeTabs) { tab in
                NavigationLink(value: tab) {
                    TabRow(tab: tab)
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if isLoading {
                    ProgressView()
                } else if activeTabs.isEmpty {
                    ContentUnavailableView(
                        "No Active Tabs",
                        systemImage: "safari",
                        description: Text("Browse websites in Safari with the devtools extension enabled to see debug logs here.")
                    )
                }
            }
            .navigationTitle("Active Tabs")
            .navigationDestination(for: TabInfo.self) { tab in
                TabDetailView(tabId: tab.tabId, tabURL: tab.tabURL)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await loadTabs()
            }
            .refreshable {
                await loadTabs()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await loadTabs()
                    }
                }
            }
        }
    }
    
    private func loadTabs() async {
        // Don't load when backgrounded
        guard scenePhase == .active || activeTabs.isEmpty else { return }
        
        guard !Task.isCancelled else { return }
        await Task.yield()
        guard !Task.isCancelled else { return }
        
        // Fetch distinct tab info - limit to recent logs to avoid loading entire database
        var tabs: [String: TabInfo] = [:]
        
        // Limit queries to prevent loading too much data
        var debugDescriptor = FetchDescriptor<DebugLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        debugDescriptor.fetchLimit = 1000
        
        var networkDescriptor = FetchDescriptor<NetworkLog>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        networkDescriptor.fetchLimit = 500
        
        do {
            let debugLogs = try modelContext.fetch(debugDescriptor)
            
            guard !Task.isCancelled else { return }
            await Task.yield()
            guard !Task.isCancelled else { return }
            
            let networkLogs = try modelContext.fetch(networkDescriptor)
            
            guard !Task.isCancelled else { return }
            
            // Process debug logs
            for log in debugLogs {
                let key = "\(log.tabId)"
                if var existing = tabs[key] {
                    existing.logCount += 1
                    if log.timestamp > existing.lastActivity {
                        existing.lastActivity = log.timestamp
                    }
                    tabs[key] = existing
                } else {
                    tabs[key] = TabInfo(
                        tabId: log.tabId,
                        tabURL: log.tabURL,
                        logCount: 1,
                        networkCount: 0,
                        lastActivity: log.timestamp
                    )
                }
            }
            
            guard !Task.isCancelled else { return }
            
            // Process network logs
            for log in networkLogs {
                let key = "\(log.tabId)"
                if var existing = tabs[key] {
                    existing.networkCount += 1
                    if log.startTime > existing.lastActivity {
                        existing.lastActivity = log.startTime
                    }
                    tabs[key] = existing
                } else {
                    tabs[key] = TabInfo(
                        tabId: log.tabId,
                        tabURL: log.tabURL,
                        logCount: 0,
                        networkCount: 1,
                        lastActivity: log.startTime
                    )
                }
            }
            
            guard !Task.isCancelled else { return }
            
            activeTabs = Array(tabs.values).sorted { $0.lastActivity > $1.lastActivity }
            isLoading = false
        } catch {
            activeTabs = []
            isLoading = false
        }
    }
}

struct TabInfo: Identifiable, Hashable {
    var id: Int { tabId }
    let tabId: Int
    let tabURL: String
    var logCount: Int
    var networkCount: Int
    var lastActivity: Date
}

struct TabRow: View {
    let tab: TabInfo
    
    var displayName: String {
        if let url = URL(string: tab.tabURL) {
            return url.host ?? tab.tabURL
        }
        return tab.tabURL
    }
    
    var body: some View {
        Text(displayName)
    }
}

#Preview {
    ContentView()
}

