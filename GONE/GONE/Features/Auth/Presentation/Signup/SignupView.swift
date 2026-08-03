//
//  SignupView.swift
//  GONE
//
//  Created by Codex on 2026-08-04.
//

import SwiftUI

struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()

    let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                    .padding(.top, GONESpacing.small)

                progressIndicator
                    .padding(.top, GONESpacing.xLarge)

                introduction
                    .padding(.top, 48)

                inputFields
                    .padding(.top, 34)
                    .id(viewModel.currentStep)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.bottom, GONESpacing.section)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GONEPrimaryButton(
                title: viewModel.currentStep.actionTitle,
                isEnabled: viewModel.isPrimaryActionEnabled,
                isLoading: false,
                action: handlePrimaryAction
            )
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.small)
            .background(Color.white)
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.goneTextPrimary)
                    .frame(width: 44, height: 44)
            }
            .background(Color.white.opacity(0.82), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            .accessibilityLabel("뒤로가기")

            Spacer()

            goneLogo

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var goneLogo: some View {
        Image("GONELogo")
            .resizable()
            .scaledToFill()
            .frame(width: 230, height: 54)
            .clipped()
        .accessibilityLabel("GONE")
    }

    private var progressIndicator: some View {
        HStack(spacing: GONESpacing.small) {
            ForEach(SignupViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.goneBrandPrimary : Color.goneBorderDefault)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.progressAccessibilityLabel)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(viewModel.currentStep.title)
                .font(GONEFont.sfPro(size: 23, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)

            Text(viewModel.currentStep.description)
                .font(GONEFont.sfPro(size: 15))
                .foregroundStyle(Color.goneTextSecondary)
                .lineSpacing(3)
        }
    }

    @ViewBuilder
    private var inputFields: some View {
        switch viewModel.currentStep {
        case .identifier:
            GONEUnderlinedTextField(
                title: "아이디",
                placeholder: "아이디를 입력해주세요",
                text: $viewModel.identifier,
                textContentType: .username,
                errorMessage: viewModel.identifierErrorMessage
            )
        case .password:
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                GONEUnderlinedTextField(
                    title: "비밀번호",
                    placeholder: "비밀번호를 입력해주세요",
                    text: $viewModel.password,
                    isSecure: true,
                    textContentType: .newPassword,
                    errorMessage: viewModel.passwordErrorMessage
                )

                GONEUnderlinedTextField(
                    title: "비밀번호 확인",
                    placeholder: "비밀번호를 다시 입력해주세요",
                    text: $viewModel.passwordConfirmation,
                    isSecure: true,
                    textContentType: .newPassword,
                    errorMessage: viewModel.confirmationErrorMessage
                )
            }
        case .phoneVerification:
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                GONEUnderlinedTextField(
                    title: "전화번호",
                    placeholder: "010-0000-0000",
                text: phoneNumberBinding,
                    textContentType: .telephoneNumber,
                    keyboardType: .phonePad,
                    errorMessage: viewModel.phoneErrorMessage,
                    trailingActionTitle: "인증번호 받기",
                    isTrailingActionEnabled: viewModel.isVerificationRequestEnabled,
                    trailingAction: viewModel.requestVerificationCode
                )

                GONEUnderlinedTextField(
                    title: "인증번호",
                    placeholder: "인증번호를 입력해주세요",
                    text: $viewModel.verificationCode,
                    textContentType: .oneTimeCode,
                    keyboardType: .numberPad,
                    errorMessage: viewModel.verificationErrorMessage
                )

                if let serviceErrorMessage = viewModel.serviceErrorMessage {
                    Text(serviceErrorMessage)
                        .font(GONEFont.sfPro(size: 14))
                        .foregroundStyle(Color.goneStatusError)
                        .accessibilityLabel("회원가입 안내: \(serviceErrorMessage)")
                }
            }
        }
    }

    private func handleBack() {
        if viewModel.currentStep == .identifier {
            onDismiss()
        } else {
            withAnimation(.snappy(duration: 0.28)) {
                viewModel.goBack()
            }
        }
    }

    private var phoneNumberBinding: Binding<String> {
        Binding(
            get: { viewModel.phoneNumber },
            set: { viewModel.updatePhoneNumber($0) }
        )
    }

    private func handlePrimaryAction() {
        withAnimation(.snappy(duration: 0.28)) {
            viewModel.proceed()
        }
    }
}

#Preview {
    SignupView()
}
