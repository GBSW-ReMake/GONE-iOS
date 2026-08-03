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

extension Color {
    static let goneBrandPrimary = Color(red: 91 / 255, green: 141 / 255, blue: 239 / 255)
    static let goneTextPrimary = Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)
    static let goneTextSecondary = Color(red: 102 / 255, green: 112 / 255, blue: 133 / 255)
    static let goneTextTertiary = Color(red: 152 / 255, green: 160 / 255, blue: 170 / 255)
    static let goneBorderDefault = Color(red: 221 / 255, green: 225 / 255, blue: 230 / 255)
    static let goneSurfaceDisabled = Color(red: 241 / 255, green: 243 / 255, blue: 245 / 255)
    static let goneStatusError = Color(red: 255 / 255, green: 90 / 255, blue: 95 / 255)
}
