//
//  AppLockState.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation
import SwiftUI

@Observable
class AppLockState {
    static let shared = AppLockState()
    
    private init() {}
    
    var isLocked: Bool = false
    var lastUnlockDate: Date?
    var errorMessage: String?
    var biometricType: BiometricType = .none
    
    private let biometricService = BiometricAuthService.shared
    
    /// Initialize lock state based on app settings
    func initializeLockState(biometricEnabled: Bool) {
        #if DEBUG
        print("🔒 AppLockState: Initializing with biometric enabled: \(biometricEnabled)")
        #endif
        
        if biometricEnabled {
            // Check biometric availability
            let availability = biometricService.checkBiometricAvailability()
            biometricType = availability.biometricType
            
            if availability.available {
                // Start locked if biometrics are enabled and available
                isLocked = true
                errorMessage = nil
                #if DEBUG
                print("🔒 AppLockState: Starting locked with \(biometricType.displayName)")
                #endif
            } else {
                // If biometrics not available, don't lock
                isLocked = false
                errorMessage = availability.error?.errorDescription
                #if DEBUG
                print("🔒 AppLockState: Biometrics not available: \(availability.error?.errorDescription ?? "Unknown")")
                #endif
            }
        } else {
            // Biometrics disabled, don't lock
            isLocked = false
            errorMessage = nil
            #if DEBUG
            print("🔒 AppLockState: Biometrics disabled, not locking")
            #endif
        }
    }
    
    /// Lock the app (called when app goes to background)
    func lockApp() {
        isLocked = true
        errorMessage = nil
        #if DEBUG
        print("🔒 AppLockState: App locked")
        #endif
    }
    
    /// Attempt to unlock the app with biometrics
    func unlockWithBiometrics() async {
        #if DEBUG
        print("🔒 AppLockState: Attempting biometric unlock...")
        #endif
        
        let reason = L10n.string("biometric_unlock_reason")
        let result = await biometricService.authenticateWithBiometrics(reason: reason)
        
        await MainActor.run {
            switch result {
            case .success:
                isLocked = false
                lastUnlockDate = Date()
                errorMessage = nil
                #if DEBUG
                print("🔒 AppLockState: Successfully unlocked")
                #endif
                
            case .failure(let error):
                // Keep locked and show error
                errorMessage = error.errorDescription
                #if DEBUG
                print("🔒 AppLockState: Unlock failed: \(error.errorDescription ?? "Unknown error")")
                #endif
            }
        }
    }
    
    /// Unlock the app without biometrics (when biometrics are disabled)
    func unlockWithoutBiometrics() {
        isLocked = false
        lastUnlockDate = Date()
        errorMessage = nil
        #if DEBUG
        print("🔒 AppLockState: Unlocked without biometrics")
        #endif
    }
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
