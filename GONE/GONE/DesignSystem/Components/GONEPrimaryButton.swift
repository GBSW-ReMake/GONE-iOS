//
//  GONEPrimaryButton.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import SwiftUI

struct GONEPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(GONEFont.sfPro(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .foregroundStyle(isEnabled ? Color.white : Color.goneTextTertiary)
        .background(isEnabled ? Color.goneBrandPrimary : Color.goneSurfaceDisabled)
        .clipShape(RoundedRectangle(cornerRadius: GONECornerRadius.button, style: .continuous))
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "로그인을 처리하고 있습니다." : "")
    }
}

#Preview {
    VStack(spacing: GONESpacing.large) {
        GONEPrimaryButton(title: "로그인", isEnabled: false, isLoading: false) {}
        GONEPrimaryButton(title: "로그인", isEnabled: true, isLoading: false) {}
        GONEPrimaryButton(title: "로그인", isEnabled: true, isLoading: true) {}
    }
    .padding()
}
