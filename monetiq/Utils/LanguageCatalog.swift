//
//  LanguageCatalog.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation

struct Language {
    let code: String
    let name: String
    
    var displayName: String {
        return name
    }
    
    /// Returns the flag emoji for this language's primary country
    var flag: String {
        return LanguageCatalog.shared.flag(for: code)
    }
}

struct LanguageCatalog {
    static let shared = LanguageCatalog()
    
    private init() {}
    
    let supportedLanguages: [Language] = [
        Language(code: "system", name: "System Default"),
        Language(code: "en", name: "English"),
        Language(code: "ro", name: "Română"),
        Language(code: "de", name: "Deutsch"),
        Language(code: "zh-Hans", name: "中文 (简体)"),
        Language(code: "hi", name: "हिन्दी"),
        Language(code: "it", name: "Italiano"),
        Language(code: "es", name: "Español"),
        Language(code: "ru", name: "Русский"),
        Language(code: "fr", name: "Français")
    ]
    
    func language(for code: String?) -> Language? {
        let searchCode = code ?? "system"
        return supportedLanguages.first { $0.code == searchCode }
    }
    
    func displayName(for code: String?) -> String {
        return language(for: code)?.displayName ?? "System Default"
    }
    
    var languageCodes: [String] {
        return supportedLanguages.map { $0.code }
    }
    
    /// Returns the flag emoji for a given language code
    /// Maps language to its primary country/region
    func flag(for code: String) -> String {
        switch code {
        case "system": return "🌐" // Globe for system default
        case "en": return "🇬🇧" // English (UK flag)
        case "ro": return "🇷🇴" // Romanian
        case "de": return "🇩🇪" // German
        case "zh-Hans": return "🇨🇳" // Chinese Simplified
        case "hi": return "🇮🇳" // Hindi
        case "it": return "🇮🇹" // Italian
        case "es": return "🇪🇸" // Spanish
        case "ru": return "🇷🇺" // Russian
        case "fr": return "🇫🇷" // French
        default: return "🌐" // Fallback: globe icon
        }
    }
}
