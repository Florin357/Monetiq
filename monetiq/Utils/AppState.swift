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
    
    func triggerAppReset() {
        resetToken = UUID()
        #if DEBUG
        print("🔄 AppState: Reset token updated to \(resetToken)")
        #endif
    }
}
