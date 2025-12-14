//
//  BiometricAuthService.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "Biometrics"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryLockout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled on this device"
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancel:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .biometryLockout:
            return "Biometric authentication is locked out"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

@Observable
class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    private init() {}
    
    private let context = LAContext()
    
    /// Check if biometric authentication is available on this device
    func checkBiometricAvailability() -> (available: Bool, biometricType: BiometricType, error: BiometricAuthError?) {
        var error: NSError?
        
        #if DEBUG
        print("🔒 BiometricAuthService: Checking biometric availability...")
        #endif
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            let biometricError = mapLAError(error)
            #if DEBUG
            print("🔒 BiometricAuthService: Biometrics not available: \(biometricError.errorDescription ?? "Unknown")")
            #endif
            return (false, .none, biometricError)
        }
        
        let biometricType = getBiometricType()
        #if DEBUG
        print("🔒 BiometricAuthService: Biometrics available: \(biometricType.displayName)")
        #endif
        return (true, biometricType, nil)
    }
    
    /// Perform biometric authentication
    func authenticateWithBiometrics(reason: String) async -> Result<Void, BiometricAuthError> {
        #if DEBUG
        print("🔒 BiometricAuthService: Starting authentication with reason: \(reason)")
        #endif
        
        // Use a fresh context for each authentication attempt
        let authContext = LAContext()
        
        // Check availability first using the same context
        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            let biometricError = mapLAError(error)
            #if DEBUG
            print("🔒 BiometricAuthService: Authentication failed - biometrics not available: \(biometricError.errorDescription ?? "Unknown")")
            #endif
            return .failure(biometricError)
        }
        
        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                #if DEBUG
                print("🔒 BiometricAuthService: Authentication successful")
                #endif
                return .success(())
            } else {
                #if DEBUG
                print("🔒 BiometricAuthService: Authentication failed - success was false")
                #endif
                return .failure(.authenticationFailed)
            }
        } catch {
            let biometricError = mapLAError(error as NSError)
            #if DEBUG
            print("🔒 BiometricAuthService: Authentication failed with error: \(biometricError.errorDescription ?? "Unknown")")
            #endif
            return .failure(biometricError)
        }
    }
    
    /// Get the specific biometric type available on this device
    private func getBiometricType() -> BiometricType {
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    /// Map LAError to our custom BiometricAuthError
    private func mapLAError(_ error: NSError?) -> BiometricAuthError {
        guard let error = error else { return .unknown(NSError()) }
        
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.authenticationFailed.rawValue:
            return .authenticationFailed
        case LAError.userCancel.rawValue:
            return .userCancel
        case LAError.userFallback.rawValue:
            return .userFallback
        case LAError.systemCancel.rawValue:
            return .systemCancel
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        case LAError.biometryLockout.rawValue:
            return .biometryLockout
        default:
            return .unknown(error)
        }
    }
}
