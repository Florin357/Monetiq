//
//  AppLinks.swift
//  monetiq
//
//  Created by Assistant on 15.12.2025.
//

import Foundation

/// Centralized configuration for app-related URLs and information
struct AppLinks {
    
    // MARK: - Legal URLs
    
    /// Privacy Policy URL - Update this with your actual privacy policy URL
    static let privacyURL = "https://monetiq.app/privacy"
    
    /// Terms of Service URL - Update this with your actual terms URL  
    static let termsURL = "https://monetiq.app/terms"
    
    // MARK: - App Information
    
    /// App version from Bundle
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Build number from Bundle
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// App name from Bundle
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Monetiq"
    }
    
    /// Complete version string for display
    static var versionString: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    /// App info subtitle for Settings
    static var appInfoSubtitle: String {
        return "\(appName) • Version \(versionString) • Made for iPhone"
    }
    
    // MARK: - URL Validation
    
    /// Validates if a URL string is properly formatted and uses HTTPS
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" else {
            return false
        }
        return true
    }
    
    /// Returns a validated URL or nil if invalid
    static func validatedURL(_ urlString: String) -> URL? {
        guard isValidURL(urlString) else { return nil }
        return URL(string: urlString)
    }
}
