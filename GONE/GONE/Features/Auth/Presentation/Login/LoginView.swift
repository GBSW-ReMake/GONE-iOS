//
//  LoginView.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    private let onLogin: ((LoginCredentials) -> Void)?
    private let onSignUpTapped: () -> Void
    private let onBackTapped: () -> Void

    init(
        role: AccountRole = .student,
        onLogin: ((LoginCredentials) -> Void)? = nil,
        onSignUpTapped: @escaping () -> Void = {},
        onBackTapped: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(role: role))
        self.onLogin = onLogin
        self.onSignUpTapped = onSignUpTapped
        self.onBackTapped = onBackTapped
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                backButton
                    .padding(.top, GONESpacing.small)

                logo
                    .padding(.top, GONESpacing.large)

                introduction
                    .padding(.top, 28)

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
        Image("GONELogo")
            .resizable()
            .scaledToFit()
            .frame(width: 88, height: 24)
            .accessibilityLabel("GONE")
    }

    private var backButton: some View {
        Button(action: onBackTapped) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.goneTextPrimary)
                .frame(width: 44, height: 44)
        }
        .contentShape(Rectangle())
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 3)
        .accessibilityLabel("로그인 유형 다시 선택")
        .accessibilityHint("학생 또는 선생님 로그인 선택 화면으로 돌아갑니다.")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("학교생활을 더 간편하게")
                .font(GONEFont.sfPro(size: 22, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)

            Text("GONE에 로그인하고 학교의 서비스를\n한곳에서 이용해보세요.")
                .font(GONEFont.sfPro(size: 15))
                .foregroundStyle(Color.goneTextSecondary)
                .lineSpacing(3)
        }
    }

    private var inputFields: some View {
        VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
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
                    .font(GONEFont.sfPro(size: 14))
                    .foregroundStyle(Color.goneStatusError)
                    .accessibilityLabel("로그인 오류: \(loginErrorMessage)")
            }
        }
    }

    private var signUpButton: some View {
        HStack(spacing: 5) {
            Text("아직 회원이 아니신가요?")
                .foregroundStyle(Color.goneTextSecondary)

            Button("회원가입", action: onSignUpTapped)
                .foregroundStyle(Color.goneBrandPrimary)
                .fontWeight(.semibold)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityHint("회원가입 화면으로 이동합니다.")
        }
        .font(GONEFont.sfPro(size: 14))
        .frame(maxWidth: .infinity)
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
