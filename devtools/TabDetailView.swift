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
    
    @Query var logs: [DebugLog]
    @State private var searchText = ""
    
    init(tabId: Int) {
        self.tabId = tabId
        let predicate = #Predicate<DebugLog> { $0.tabId == tabId }
        _logs = Query(filter: predicate, sort: \DebugLog.timestamp, order: .reverse)
    }
    
    var filteredLogs: [DebugLog] {
        if searchText.isEmpty {
            return logs
        }
        return logs.filter { $0.args.joined().localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if logs.isEmpty {
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
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Filter logs")
    }
}

struct LogRow: View {
    let log: DebugLog
    
    private var iconName: String {
        switch log.type {
        case "error":
            return "xmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "info":
            return "info.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch log.type {
        case "error":
            return .red
        case "warn":
            return .orange
        case "info":
            return .blue
        default:
            return .secondary
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.args.joined(separator: " "))
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(5)
                
                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Network View

struct NetworkListView: View {
    let tabId: Int
    
    @Query var requests: [NetworkLog]
    @State private var searchText = ""
    @State private var selectedRequest: NetworkLog?
    
    init(tabId: Int) {
        self.tabId = tabId
        let predicate = #Predicate<NetworkLog> { $0.tabId == tabId }
        _requests = Query(filter: predicate, sort: \NetworkLog.startTime, order: .reverse)
    }
    
    var filteredRequests: [NetworkLog] {
        if searchText.isEmpty {
            return requests
        }
        return requests.filter { $0.url.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if requests.isEmpty {
                ContentUnavailableView(
                    "No Network Requests",
                    systemImage: "network",
                    description: Text("Network requests will appear here.")
                )
            } else if filteredRequests.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filteredRequests) { request in
                    Button {
                        selectedRequest = request
                    } label: {
                        NetworkRow(request: request)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Filter by URL")
        .sheet(item: $selectedRequest) { request in
            NetworkDetailView(request: request)
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
                .font(.system(.footnote, design: .monospaced))
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
                
                Section("Timing") {
                    LabeledContent("Started", value: request.startTime, format: .dateTime)
                    if let endTime = request.endTime {
                        LabeledContent("Completed", value: endTime, format: .dateTime)
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

