//
//  LockScreenView.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import SwiftUI

struct LockScreenView: View {
    @State private var lockState = AppLockState.shared
    @State private var isUnlocking = false
    
    var body: some View {
        ZStack {
            // Background
            MonetiqTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: MonetiqTheme.Spacing.xl) {
                Spacer()
                
                // Lock Icon
                VStack(spacing: MonetiqTheme.Spacing.lg) {
                    Image(systemName: biometricIconName)
                        .font(.system(size: 80))
                        .foregroundColor(MonetiqTheme.Colors.accent)
                    
                    VStack(spacing: MonetiqTheme.Spacing.md) {
                        Text(L10n.string("lock_screen_title"))
                            .font(MonetiqTheme.Typography.largeTitle)
                            .foregroundColor(MonetiqTheme.Colors.onBackground)
                            .fontWeight(.bold)
                        
                        Text(L10n.string("lock_screen_subtitle", lockState.biometricType.displayName))
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MonetiqTheme.Spacing.lg)
                    }
                }
                
                Spacer()
                
                // Error Message
                if let errorMessage = lockState.errorMessage {
                    VStack(spacing: MonetiqTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(MonetiqTheme.Colors.error)
                        
                        Text(errorMessage)
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MonetiqTheme.Spacing.lg)
                    }
                    .padding(MonetiqTheme.Spacing.md)
                    .background(MonetiqTheme.Colors.error.opacity(0.1))
                    .cornerRadius(MonetiqTheme.CornerRadius.md)
                    .padding(.horizontal, MonetiqTheme.Spacing.lg)
                }
                
                // Unlock Button
                Button(action: unlockApp) {
                    HStack(spacing: MonetiqTheme.Spacing.sm) {
                        if isUnlocking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: MonetiqTheme.Colors.onPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: biometricIconName)
                                .font(.title3)
                        }
                        
                        Text(L10n.string("lock_screen_unlock_button", lockState.biometricType.displayName))
                            .font(MonetiqTheme.Typography.headline)
                    }
                    .foregroundColor(MonetiqTheme.Colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(MonetiqTheme.Spacing.md)
                    .background(MonetiqTheme.Colors.accent)
                    .cornerRadius(MonetiqTheme.CornerRadius.md)
                }
                .disabled(isUnlocking)
                .padding(.horizontal, MonetiqTheme.Spacing.lg)
                
                Spacer()
            }
        }
        .onAppear {
            // Clear any previous error when screen appears
            lockState.clearError()
        }
    }
    
    private var biometricIconName: String {
        switch lockState.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
    
    private func unlockApp() {
        isUnlocking = true
        lockState.clearError()
        
        Task {
            await lockState.unlockWithBiometrics()
            
            await MainActor.run {
                isUnlocking = false
            }
        }
    }
}

#Preview {
    LockScreenView()
}
