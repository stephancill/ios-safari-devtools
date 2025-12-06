//
//  DevToolsApp.swift
//  devtools
//

import SwiftUI
import SwiftData

@main
struct DevToolsApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([DebugLog.self, NetworkLog.self])
        let config = ModelConfiguration(
            schema: schema,
            url: FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Settings.suiteName)!
                .appendingPathComponent("logs.store"),
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

