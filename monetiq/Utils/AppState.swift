//
//  AppState.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation

@Observable
class AppState {
    static let shared = AppState()
    
    private init() {}
    
    var resetToken = UUID()
    var isResetting = false
    
    func triggerAppReset() {
        resetToken = UUID()
        #if DEBUG
        print("🔄 AppState: Reset token updated to \(resetToken)")
        #endif
    }
    
    func beginReset() {
        isResetting = true
        #if DEBUG
        print("🔄 AppState: Reset started, isResetting = true")
        #endif
    }
    
    func endReset() {
        isResetting = false
        #if DEBUG
        print("✅ AppState: Reset completed, isResetting = false")
        #endif
    }
}
