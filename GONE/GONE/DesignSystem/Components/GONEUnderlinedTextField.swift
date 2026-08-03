//
//  GONEUnderlinedTextField.swift
//  GONE
//  Created by Codex on 2026-08-03.
//

import SwiftUI
import UIKit

struct GONEUnderlinedTextField: View {
    let title: String
    let placeholder: String
    let isSecure: Bool
    let textContentType: UITextContentType?
    let keyboardType: UIKeyboardType
    let errorMessage: String?
    let trailingActionTitle: String?
    let isTrailingActionEnabled: Bool
    let trailingAction: (() -> Void)?

    @Binding private var text: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil,
        trailingActionTitle: String? = nil,
        isTrailingActionEnabled: Bool = true,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.textContentType = textContentType
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
        self.trailingActionTitle = trailingActionTitle
        self.isTrailingActionEnabled = isTrailingActionEnabled
        self.trailingAction = trailingAction
    }

    private var underlineColor: Color {
        if errorMessage != nil {
            return .goneStatusError
        }

        return isFocused ? .goneBrandPrimary : .goneBorderDefault
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(GONEFont.sfPro(size: 13, weight: .medium))
                .foregroundStyle(Color.goneTextSecondary)

            HStack(spacing: GONESpacing.small) {
                Group {
                    if isSecure {
                        SecureField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(Color.goneTextTertiary)
                        )
                    } else {
                        TextField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(Color.goneTextTertiary)
                        )
                    }
                }
                .font(GONEFont.sfPro(size: 17))
                .foregroundStyle(Color.goneTextPrimary)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)

                if let trailingActionTitle, let trailingAction {
                    Button {
                        guard isTrailingActionEnabled else { return }
                        trailingAction()
                    } label: {
                        Text(trailingActionTitle)
                            .font(GONEFont.sfPro(size: 14, weight: .semibold))
                            .foregroundStyle(
                                isTrailingActionEnabled
                                    ? Color.goneBrandPrimary
                                    : Color.goneTextTertiary
                            )
                            .padding(.horizontal, GONESpacing.medium)
                            .frame(minHeight: 36)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(
                                        isTrailingActionEnabled
                                            ? Color.goneBrandPrimary
                                            : Color.goneBorderDefault,
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityHint(
                        isTrailingActionEnabled
                            ? "인증번호를 요청합니다."
                            : "전화번호를 입력한 후 사용할 수 있습니다."
                    )
                }
            }
            .padding(.vertical, 2)
            .frame(minHeight: 48)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(underlineColor)
                    .frame(height: 2)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(GONEFont.sfPro(size: 13))
                    .foregroundStyle(Color.goneStatusError)
                    .accessibilityLabel("오류: \(errorMessage)")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    GONEUnderlinedTextField(
        title: "아이디",
        placeholder: "아이디 또는 전화번호를 입력해주세요",
        text: .constant("")
    )
    .padding()
}
