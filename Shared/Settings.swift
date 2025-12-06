//
//  Settings.swift
//  devtools
//
//  Shared settings between the host app and extension.
//  Add this file to both targets.
//

import Foundation

struct Settings {
    static let suiteName = "group.co.za.stephancill.devtools"
    
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }
    
    // MARK: - Storage Limits
    
    static var maxLogsPerTab: Int {
        get { defaults.integer(forKey: "maxLogsPerTab").nonZero ?? 500 }
        set { defaults.set(newValue, forKey: "maxLogsPerTab") }
    }
    
    static var maxNetworkRequestsPerTab: Int {
        get { defaults.integer(forKey: "maxNetworkRequestsPerTab").nonZero ?? 200 }
        set { defaults.set(newValue, forKey: "maxNetworkRequestsPerTab") }
    }
    
    static var maxResponseBodySize: Int {
        get { defaults.integer(forKey: "maxResponseBodySize").nonZero ?? 10_000 } // 10KB
        set { defaults.set(newValue, forKey: "maxResponseBodySize") }
    }
    
    // MARK: - Data Retention
    
    static var logRetentionHours: Int {
        get { defaults.integer(forKey: "logRetentionHours").nonZero ?? 24 }
        set { defaults.set(newValue, forKey: "logRetentionHours") }
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

