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
}

struct LanguageCatalog {
    static let shared = LanguageCatalog()
    
    private init() {}
    
    let supportedLanguages: [Language] = [
        Language(code: "system", name: "System Default"),
        Language(code: "en", name: "English"),
        Language(code: "ro", name: "Română"),
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
}
