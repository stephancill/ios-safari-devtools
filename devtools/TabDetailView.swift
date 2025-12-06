//
//  TabDetailView.swift
//  devtools
//

import SwiftUI
import SwiftData

struct TabDetailView: View {
    let tabId: Int
    let tabURL: String
    
    var displayURL: String {
        if let url = URL(string: tabURL) {
            return url.host ?? tabURL
        }
        return tabURL
    }
    
    var body: some View {
        TabView {
            ConsoleView(tabId: tabId)
                .tabItem {
                    Label("Console", systemImage: "terminal")
                }
            
            NetworkListView(tabId: tabId)
                .tabItem {
                    Label("Network", systemImage: "network")
                }
        }
        .navigationTitle(displayURL)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Console View

struct ConsoleView: View {
    let tabId: Int
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var logs: [DebugLog] = []
    @State private var searchText = ""
    @State private var isLoading = false
    
    var filteredLogs: [DebugLog] {
        if searchText.isEmpty {
            return logs
        }
        return logs.filter { $0.args.joined().localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                ProgressView("Loading...")
            } else if logs.isEmpty {
                ContentUnavailableView(
                    "No Console Logs",
                    systemImage: "terminal",
                    description: Text("Console output will appear here.")
                )
            } else if filteredLogs.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filteredLogs) { log in
                    LogRow(log: log)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(log.rowBackgroundColor)
                        .id(log.id)
                }
                .listStyle(.plain)
                .defaultScrollAnchor(.bottom)
            }
        }
        .searchable(text: $searchText, prompt: "Filter logs")
        .task(id: tabId) {
            await fetchLogs()
        }
        .refreshable {
            await fetchLogs()
        }
    }
    
    private func fetchLogs() async {
        // Don't fetch if app is not active to avoid watchdog timeout
        guard scenePhase == .active else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check for cancellation before starting
        guard !Task.isCancelled else { return }
        
        // Yield to allow UI to update and check for cancellation
        await Task.yield()
        guard !Task.isCancelled else { return }
        
        let targetTabId = tabId
        var descriptor = FetchDescriptor<DebugLog>(
            predicate: #Predicate { $0.tabId == targetTabId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        // Reduced limit to prevent watchdog timeout
        descriptor.fetchLimit = 200
        
        do {
            let fetchedLogs = try modelContext.fetch(descriptor)
            
            // Check for cancellation after fetch
            guard !Task.isCancelled else { return }
            
            // Reverse to show oldest first, but we fetched newest first with limit
            logs = fetchedLogs.reversed()
        } catch {
            logs = []
        }
    }
}

struct LogRow: View {
    let log: DebugLog
    
    private var textColor: Color {
        switch log.type {
        case "error":
            return .red
        case "warn":
            return .orange
        case "info":
            return .blue
        default:
            return .primary
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(log.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Text(log.args.joined(separator: " "))
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

extension DebugLog {
    var rowBackgroundColor: Color {
        switch type {
        case "error":
            return .red.opacity(0.1)
        case "warn":
            return .orange.opacity(0.1)
        default:
            return .clear
        }
    }
}

// MARK: - Network View

struct NetworkListView: View {
    let tabId: Int
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var requests: [NetworkLog] = []
    @State private var selectedRequest: NetworkLog?
    @State private var searchText = ""
    @State private var isLoading = false
    
    var filteredRequests: [NetworkLog] {
        if searchText.isEmpty {
            return requests
        }
        return requests.filter { $0.url.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if isLoading && requests.isEmpty {
                ProgressView("Loading...")
            } else if requests.isEmpty {
                ContentUnavailableView(
                    "No Network Requests",
                    systemImage: "network",
                    description: Text("Network requests will appear here.")
                )
            } else if filteredRequests.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                // Full feature set matching ConsoleView
                List(filteredRequests) { request in
                    Button {
                        selectedRequest = request
                    } label: {
                        NetworkRow(request: request)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .defaultScrollAnchor(.bottom)
            }
        }
        .searchable(text: $searchText, prompt: "Filter requests")
        .task(id: tabId) {
            await fetchRequests()
        }
        .refreshable {
            await fetchRequests()
        }
        .sheet(item: $selectedRequest) { request in
            NetworkDetailView(request: request)
        }
    }
    
    private func fetchRequests() async {
        // Don't fetch if app is not active to avoid watchdog timeout
        guard scenePhase == .active else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check for cancellation before starting
        guard !Task.isCancelled else { return }
        
        // Yield to allow UI to update and check for cancellation
        await Task.yield()
        guard !Task.isCancelled else { return }
        
        let targetTabId = tabId
        var descriptor = FetchDescriptor<NetworkLog>(
            predicate: #Predicate { $0.tabId == targetTabId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        
        do {
            let fetchedRequests = try modelContext.fetch(descriptor)
            
            // Check for cancellation after fetch
            guard !Task.isCancelled else { return }
            
            requests = fetchedRequests
        } catch {
            requests = []
        }
    }
}

struct NetworkRow: View {
    let request: NetworkLog
    
    private var statusColor: Color {
        guard let status = request.status else {
            return request.error != nil ? .red : .secondary
        }
        switch status {
        case 200..<300:
            return .green
        case 300..<400:
            return .blue
        case 400..<500:
            return .orange
        case 500...:
            return .red
        default:
            return .secondary
        }
    }
    
    private var duration: String? {
        guard let endTime = request.endTime else { return nil }
        let ms = endTime.timeIntervalSince(request.startTime) * 1000
        return String(format: "%.0fms", ms)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(request.method)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                if let status = request.status {
                    Text("\(status)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                } else if request.error != nil {
                    Text("Error")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                } else {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let duration = duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Text(request.url)
                .font(.footnote)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct NetworkDetailView: View {
    let request: NetworkLog
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Request") {
                    LabeledContent("Method", value: request.method)
                    LabeledContent("URL", value: request.url)
                    
                    if let headers = request.requestHeaders, !headers.isEmpty {
                        DisclosureGroup("Headers") {
                            ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                                LabeledContent(key, value: headers[key] ?? "")
                            }
                        }
                    }
                    
                    if let body = request.requestBody {
                        DisclosureGroup("Body") {
                            Text(body)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                
                Section("Response") {
                    if let status = request.status {
                        LabeledContent("Status", value: "\(status) \(request.statusText ?? "")")
                    }
                    
                    if let error = request.error {
                        LabeledContent("Error", value: error)
                            .foregroundStyle(.red)
                    }
                    
                    if let headers = request.responseHeaders, !headers.isEmpty {
                        DisclosureGroup("Headers") {
                            ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                                LabeledContent(key, value: headers[key] ?? "")
                            }
                        }
                    }
                    
                    if let body = request.responseBody {
                        DisclosureGroup("Body") {
                            Text(body)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                
                if let endTime = request.endTime {
                    Section("Timing") {
                        let duration = endTime.timeIntervalSince(request.startTime) * 1000
                        LabeledContent("Duration", value: String(format: "%.0f ms", duration))
                    }
                }
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TabDetailView(tabId: 1, tabURL: "https://example.com")
}

