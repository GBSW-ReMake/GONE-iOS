//
//  GONETheme.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import SwiftUI

enum GONESpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
    static let screenHorizontal: CGFloat = 24
    static let section: CGFloat = 32
}

enum GONECornerRadius {
    static let button: CGFloat = 16
}

enum GONEFont {
    static func sfPro(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension Color {
    static let goneBrandPrimary = Color(red: 91 / 255, green: 141 / 255, blue: 239 / 255)
    static let goneTextPrimary = Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)
    static let goneTextSecondary = Color(red: 102 / 255, green: 112 / 255, blue: 133 / 255)
    static let goneTextTertiary = Color(red: 152 / 255, green: 160 / 255, blue: 170 / 255)
    static let goneBorderDefault = Color(red: 221 / 255, green: 225 / 255, blue: 230 / 255)
    static let goneSurfaceDisabled = Color(red: 241 / 255, green: 243 / 255, blue: 245 / 255)
    static let goneStatusError = Color(red: 255 / 255, green: 90 / 255, blue: 95 / 255)
    static let goneSurfacePrimary = Color.white
    static let goneScreenBackground = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
    static let goneStatusWaiting = Color(red: 163 / 255, green: 171 / 255, blue: 184 / 255)
    static let goneStatusOuting = Color(red: 255 / 255, green: 181 / 255, blue: 65 / 255)
    static let goneStatusReturn = Color(red: 255 / 255, green: 88 / 255, blue: 96 / 255)
}
