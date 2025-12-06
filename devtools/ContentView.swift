//
//  ContentView.swift
//  devtools
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \DebugLog.timestamp, order: .reverse) var logs: [DebugLog]
    @Query(sort: \NetworkLog.startTime, order: .reverse) var networkLogs: [NetworkLog]
    @State private var showSettings = false
    
    var activeTabs: [TabInfo] {
        var tabs: [String: TabInfo] = [:]
        
        // Gather unique tabs from logs
        for log in logs {
            let key = "\(log.tabId)"
            if tabs[key] == nil {
                tabs[key] = TabInfo(
                    tabId: log.tabId,
                    tabURL: log.tabURL,
                    logCount: 0,
                    networkCount: 0,
                    lastActivity: log.timestamp
                )
            }
            tabs[key]?.logCount += 1
            if log.timestamp > tabs[key]!.lastActivity {
                tabs[key]?.lastActivity = log.timestamp
            }
        }
        
        // Gather unique tabs from network logs
        for log in networkLogs {
            let key = "\(log.tabId)"
            if tabs[key] == nil {
                tabs[key] = TabInfo(
                    tabId: log.tabId,
                    tabURL: log.tabURL,
                    logCount: 0,
                    networkCount: 0,
                    lastActivity: log.startTime
                )
            }
            tabs[key]?.networkCount += 1
            if log.startTime > tabs[key]!.lastActivity {
                tabs[key]?.lastActivity = log.startTime
            }
        }
        
        return Array(tabs.values).sorted { $0.lastActivity > $1.lastActivity }
    }
    
    var body: some View {
        NavigationStack {
            List(activeTabs) { tab in
                NavigationLink(value: tab) {
                    TabRow(tab: tab)
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if activeTabs.isEmpty {
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

