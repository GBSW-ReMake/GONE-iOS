//
//  SignupView.swift
//  GONE
//
//  Created by Codex on 2026-08-04.
//

import PhotosUI
import SwiftUI
import UIKit

struct SignupView: View {
    @StateObject private var viewModel: SignupViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProfileImageLoading = false

    let onDismiss: () -> Void

    init(
        signupUseCase: SignupUseCase? = nil,
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: SignupViewModel(signupUseCase: signupUseCase))
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

                if let serviceErrorMessage = viewModel.serviceErrorMessage {
                    Text(serviceErrorMessage)
                        .font(GONEFont.sfPro(size: 14))
                        .foregroundStyle(Color.goneStatusError)
                        .padding(.top, GONESpacing.large)
                        .accessibilityLabel("회원가입 안내: \(serviceErrorMessage)")
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.bottom, GONESpacing.section)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
            guard let selectedPhotoItem else { return }

            Task {
                await loadProfileImage(from: selectedPhotoItem)
            }
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GONEPrimaryButton(
                title: viewModel.currentStep.actionTitle,
                isEnabled: viewModel.isPrimaryActionEnabled,
                isLoading: viewModel.isSendingVerificationCode || viewModel.isSigningUp,
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
        HStack(spacing: 0) {
            Text("G").foregroundStyle(Color.goneBrandPrimary)
            Text("ONE").foregroundStyle(Color.goneTextPrimary)
        }
        .font(GONEFont.sfPro(size: 29, weight: .bold))
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

                if let verificationCooldownText = viewModel.verificationCooldownText {
                    Text(verificationCooldownText)
                        .font(GONEFont.sfPro(size: 13))
                        .foregroundStyle(Color.goneTextTertiary)
                }

                GONEUnderlinedTextField(
                    title: "인증번호",
                    placeholder: "인증번호를 입력해주세요",
                    text: $viewModel.verificationCode,
                    textContentType: .oneTimeCode,
                    keyboardType: .numberPad,
                    errorMessage: viewModel.verificationErrorMessage
                )

                if let verificationCodeExpiryText = viewModel.verificationCodeExpiryText {
                    Text(verificationCodeExpiryText)
                        .font(GONEFont.sfPro(size: 13))
                        .foregroundStyle(Color.goneTextTertiary)
                }

            }
        case .studentInformation:
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                GONEUnderlinedTextField(
                    title: "학번",
                    placeholder: "1101",
                    text: $viewModel.studentNumber,
                    textContentType: .none,
                    keyboardType: .numberPad,
                    errorMessage: viewModel.studentNumberErrorMessage
                )

                GONEUnderlinedTextField(
                    title: "이름",
                    placeholder: "홍길동",
                    text: $viewModel.name,
                    textContentType: .name,
                    errorMessage: viewModel.nameErrorMessage
                )
            }
        case .profileImage:
            profileImagePicker
        }
    }

    private var profileImagePicker: some View {
        VStack(spacing: GONESpacing.large) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 58, weight: .medium))
                                .foregroundStyle(Color.goneTextTertiary)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.goneSurfaceDisabled)
                    .clipShape(Circle())

                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.goneBrandPrimary, in: Circle())
                        .overlay {
                            Circle().stroke(Color.white, lineWidth: 3)
                        }
                }
                .overlay {
                    if isProfileImageLoading {
                        ProgressView()
                            .tint(Color.goneBrandPrimary)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("프로필 사진 선택")
            .accessibilityValue(viewModel.profileImageData == nil ? "선택 사항, 기본 이미지" : "선택한 프로필 사진")
            .accessibilityHint("사진을 선택하지 않아도 계속할 수 있습니다.")

            Text("사진을 선택하지 않아도 괜찮아요")
                .font(GONEFont.sfPro(size: 14))
                .foregroundStyle(Color.goneTextSecondary)

            if let profileImageErrorMessage = viewModel.profileImageErrorMessage {
                Text(profileImageErrorMessage)
                    .font(GONEFont.sfPro(size: 13))
                    .foregroundStyle(Color.goneStatusError)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("오류: \(profileImageErrorMessage)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var profileImage: UIImage? {
        guard let profileImageData = viewModel.profileImageData else { return nil }
        return UIImage(data: profileImageData)
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

    @MainActor
    private func loadProfileImage(from item: PhotosPickerItem) async {
        isProfileImageLoading = true
        defer { isProfileImageLoading = false }

        do {
            viewModel.updateProfileImage(data: try await item.loadTransferable(type: Data.self))
        } catch {
            viewModel.reportProfileImageLoadingFailure()
        }
    }
}

#Preview {
    SignupView()
}
