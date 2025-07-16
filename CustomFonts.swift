import SwiftUI

// MARK: - App Design System
// This file contains the design system constants used throughout the app

// MARK: - Typography Scale
struct AppFonts {
    static let title = Font.system(size: 28, weight: .bold)
    static let headline = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let timer = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let caption = Font.system(size: 14, weight: .regular)
}

// MARK: - Color Palette
struct AppColors {
    static let background = Color.white
    static let primary = Color.black
    static let secondary = Color.gray  // Visible gray for secondary text
    static let accent = Color.blue
    static let cardBackground = Color.gray.opacity(0.05)
    static let border = Color.gray.opacity(0.1)
}

// MARK: - Design Tokens
struct AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
} 
