//
//  SettingsView.swift
//  devtools
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("maxLogsPerTab", store: UserDefaults(suiteName: Settings.suiteName))
    private var maxLogsPerTab = 500
    
    @AppStorage("maxNetworkRequestsPerTab", store: UserDefaults(suiteName: Settings.suiteName))
    private var maxNetworkRequestsPerTab = 200
    
    @AppStorage("logRetentionHours", store: UserDefaults(suiteName: Settings.suiteName))
    private var logRetentionHours = 24
    
    @State private var showClearConfirmation = false
    @State private var showSetupInstructions = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showSetupInstructions = true
                    } label: {
                        HStack {
                            Label("Setup Instructions", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                Section {
                    Stepper("Max logs per tab: \(maxLogsPerTab)", 
                            value: $maxLogsPerTab, in: 100...2000, step: 100)
                    Stepper("Max requests per tab: \(maxNetworkRequestsPerTab)", 
                            value: $maxNetworkRequestsPerTab, in: 50...500, step: 50)
                } header: {
                    Text("Storage Limits")
                } footer: {
                    Text("Older entries are automatically removed when limits are exceeded.")
                }
                
                Section {
                    Picker("Keep logs for", selection: $logRetentionHours) {
                        Text("1 hour").tag(1)
                        Text("6 hours").tag(6)
                        Text("24 hours").tag(24)
                        Text("7 days").tag(168)
                    }
                } header: {
                    Text("Data Retention")
                } footer: {
                    Text("Logs older than this will be automatically deleted.")
                }
                
                Section {
                    Button("Clear All Data", role: .destructive) {
                        showClearConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Clear All Data?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all console logs and network requests. This action cannot be undone.")
            }
            .sheet(isPresented: $showSetupInstructions) {
                SetupInstructionsView()
            }
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: DebugLog.self)
            try modelContext.delete(model: NetworkLog.self)
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

struct SetupInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Image("LargeIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                    
                    VStack(spacing: 16) {
                        Text("Enable devtools Extension")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(number: 1, text: "Open the Settings app")
                            InstructionRow(number: 2, text: "Go to Apps → Safari → Extensions")
                            InstructionRow(number: 3, text: "Tap on devtools")
                            InstructionRow(number: 4, text: "Enable the extension")
                            InstructionRow(number: 5, text: "Allow for All Websites or specific sites")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Setup")
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

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    SettingsView()
}

