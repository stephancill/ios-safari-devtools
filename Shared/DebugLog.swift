//
//  DebugLog.swift
//  devtools
//

import SwiftData
import Foundation

@Model
class DebugLog {
    @Attribute(.unique) var id: String
    var tabId: Int
    var tabURL: String
    var type: String  // log, warn, error, info
    var args: [String]
    var timestamp: Date
    
    init(id: String, tabId: Int, tabURL: String, type: String, args: [String], timestamp: Date) {
        self.id = id
        self.tabId = tabId
        self.tabURL = tabURL
        self.type = type
        self.args = args
        self.timestamp = timestamp
    }
}
