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

    @Binding private var text: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.textContentType = textContentType
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
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

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(GONEFont.sfPro(size: 17))
            .foregroundStyle(Color.goneTextPrimary)
            .textContentType(textContentType)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .padding(.vertical, 10)
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
