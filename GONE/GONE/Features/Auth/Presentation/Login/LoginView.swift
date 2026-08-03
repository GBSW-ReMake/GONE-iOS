//
//  LoginView.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    private let onLogin: ((LoginCredentials) -> Void)?
    private let onSignUpTapped: () -> Void

    init(
        onLogin: ((LoginCredentials) -> Void)? = nil,
        onSignUpTapped: @escaping () -> Void = {}
    ) {
        self.onLogin = onLogin
        self.onSignUpTapped = onSignUpTapped
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                logo
                    .padding(.top, GONESpacing.xLarge)

                introduction
                    .padding(.top, 48)

                inputFields
                    .padding(.top, 34)

                signUpButton
                    .padding(.top, GONESpacing.xLarge)
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.bottom, GONESpacing.section)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GONEPrimaryButton(
                title: "로그인",
                isEnabled: viewModel.isLoginEnabled,
                isLoading: false,
                action: submit
            )
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.small)
            .background(Color.white)
        }
    }

    private var logo: some View {
        HStack(spacing: 0) {
            Text("G")
                .foregroundStyle(Color.goneBrandPrimary)
            Text("ONE")
                .foregroundStyle(Color.goneTextPrimary)
        }
        .font(.system(size: 27, weight: .bold))
        .accessibilityLabel("GONE")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("학교생활을 더 간편하게")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)

            Text("GONE에 로그인하고 학교의 서비스를\n한곳에서 이용해보세요.")
                .font(.system(size: 14))
                .foregroundStyle(Color.goneTextSecondary)
                .lineSpacing(3)
        }
    }

    private var inputFields: some View {
        VStack(spacing: GONESpacing.xLarge) {
            GONEUnderlinedTextField(
                title: "아이디",
                placeholder: "아이디 또는 전화번호를 입력해주세요",
                text: $viewModel.identifier,
                textContentType: .username,
                errorMessage: viewModel.identifierErrorMessage
            )

            GONEUnderlinedTextField(
                title: "비밀번호",
                placeholder: "비밀번호를 입력해주세요",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password,
                errorMessage: viewModel.passwordErrorMessage
            )

            if let loginErrorMessage = viewModel.loginErrorMessage {
                Text(loginErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.goneStatusError)
                    .accessibilityLabel("로그인 오류: \(loginErrorMessage)")
            }
        }
    }

    private var signUpButton: some View {
        Button(action: onSignUpTapped) {
            HStack(spacing: 5) {
                Text("아직 회원이 아니신가요?")
                    .foregroundStyle(Color.goneTextSecondary)
                Text("회원가입")
                    .foregroundStyle(Color.goneBrandPrimary)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 13))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .accessibilityLabel("회원가입")
        .accessibilityHint("회원가입 화면으로 이동합니다.")
    }

    private func submit() {
        guard let credentials = viewModel.makeCredentials() else {
            return
        }

        guard let onLogin else {
            viewModel.showServiceUnavailableMessage()
            return
        }

        onLogin(credentials)
    }
}

#Preview {
    LoginView()
}
