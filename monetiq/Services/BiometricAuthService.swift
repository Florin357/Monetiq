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

@MainActor
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    private init() {}
    
    private let context = LAContext()
    
    /// Check if biometric authentication is available on this device
    func checkBiometricAvailability() -> (available: Bool, biometricType: BiometricType, error: BiometricAuthError?) {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let biometricError = mapLAError(error)
            return (false, .none, biometricError)
        }
        
        let biometricType = getBiometricType()
        return (true, biometricType, nil)
    }
    
    /// Perform biometric authentication
    func authenticateWithBiometrics(reason: String) async -> Result<Void, BiometricAuthError> {
        let context = LAContext()
        
        // Check availability first
        let availability = checkBiometricAvailability()
        guard availability.available else {
            return .failure(availability.error ?? .notAvailable)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                return .success(())
            } else {
                return .failure(.authenticationFailed)
            }
        } catch {
            let biometricError = mapLAError(error as NSError)
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
