//
//  SignupViewModel.swift
//  GONE
//
//  Created by Codex on 2026-08-04.
//

import Combine
import Foundation

@MainActor
final class SignupViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case identifier
        case password
        case phoneVerification
        case studentInformation
        case profileImage

        var title: String {
            switch self {
            case .identifier:
                "아이디를 입력해주세요"
            case .password:
                "비밀번호를 설정해주세요"
            case .phoneVerification:
                "전화번호를 입력해주세요"
            case .studentInformation:
                "학번 이름을 입력해주세요"
            case .profileImage:
                "프로필 사진을 설정해주세요"
            }
        }

        var description: String {
            switch self {
            case .identifier:
                "GONE에서 사용할 아이디를 입력해주세요."
            case .password:
                "안전한 서비스 이용을 위해 비밀번호를 설정해주세요."
            case .phoneVerification:
                "서비스 이용을 위해 전화번호 인증이 필요해요."
            case .studentInformation:
                "학번 이름을 입력해 주세요."
            case .profileImage:
                "나중에 언제든지 바꿀 수 있어요."
            }
        }

        var actionTitle: String {
            self == .profileImage ? "시작하기" : "다음"
        }
    }

    @Published private(set) var currentStep: Step = .identifier
    @Published var identifier = "" {
        didSet { identifierErrorMessage = nil }
    }
    @Published var password = "" {
        didSet {
            passwordErrorMessage = nil
            confirmationErrorMessage = nil
        }
    }
    @Published var passwordConfirmation = "" {
        didSet { confirmationErrorMessage = nil }
    }
    @Published var phoneNumber = ""
    @Published var verificationCode = "" {
        didSet { verificationErrorMessage = nil }
    }
    @Published var studentNumber = "" {
        didSet { studentNumberErrorMessage = nil }
    }
    @Published var name = "" {
        didSet { nameErrorMessage = nil }
    }
    @Published private(set) var profileImageData: Data?

    @Published private(set) var identifierErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var confirmationErrorMessage: String?
    @Published private(set) var phoneErrorMessage: String?
    @Published private(set) var verificationErrorMessage: String?
    @Published private(set) var studentNumberErrorMessage: String?
    @Published private(set) var nameErrorMessage: String?
    @Published private(set) var profileImageErrorMessage: String?
    @Published private(set) var serviceErrorMessage: String?
    @Published private(set) var isVerificationRequested = false
    @Published private(set) var isSendingVerificationCode = false
    @Published private(set) var isSigningUp = false

    private let signupUseCase: SignupUseCase?

    init(signupUseCase: SignupUseCase? = nil) {
        self.signupUseCase = signupUseCase
    }

    var isPrimaryActionEnabled: Bool {
        switch currentStep {
        case .identifier:
            !trimmedIdentifier.isEmpty
        case .password:
            !password.isEmpty && password == passwordConfirmation
        case .phoneVerification:
            isValidPhoneNumber && !verificationCode.isEmpty
        case .studentInformation:
            !trimmedStudentNumber.isEmpty && !trimmedName.isEmpty
        case .profileImage:
            true
        }
    }

    var isVerificationRequestEnabled: Bool {
        isValidPhoneNumber
    }

    var progressAccessibilityLabel: String {
        "회원가입 " + String(currentStep.rawValue + 1) + "단계, 전체 " + String(Step.allCases.count) + "단계"
    }

    func proceed() {
        serviceErrorMessage = nil

        switch currentStep {
        case .identifier:
            guard validateIdentifier() else { return }
            currentStep = .password
        case .password:
            guard validatePassword() else { return }
            currentStep = .phoneVerification
        case .phoneVerification:
            guard validatePhoneVerification() else { return }
            guard let signupUseCase else {
                // UI 단위 테스트와 오프라인 프리뷰에서는 단계 전환만 허용합니다.
                currentStep = .studentInformation
                return
            }
            guard !isSigningUp else { return }

            isSigningUp = true
            Task {
                do {
                    let ticket = try await signupUseCase.verifyPhoneCode(
                        verificationCode,
                        for: normalizedPhoneNumber
                    )
                    try await signupUseCase.signup(with: SignupRequest(
                        identifier: trimmedIdentifier,
                        password: password,
                        phoneNumber: normalizedPhoneNumber,
                        ticket: ticket
                    ))
                    currentStep = .studentInformation
                } catch {
                    serviceErrorMessage = Self.message(for: error)
                }
                isSigningUp = false
            }
        case .studentInformation:
            guard validateStudentInformation() else { return }
            currentStep = .profileImage
        case .profileImage:
            serviceErrorMessage = "회원가입 서비스 연결 정보를 확인 중입니다. 잠시 후 다시 시도해주세요."
        }
    }

    func goBack() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        serviceErrorMessage = nil
        currentStep = previousStep
    }

    func requestVerificationCode() {
        guard validatePhoneNumber() else { return }

        guard let signupUseCase else {
            serviceErrorMessage = "인증번호 발송 서비스 연결 정보를 확인 중입니다."
            return
        }
        guard !isSendingVerificationCode else { return }

        isSendingVerificationCode = true
        verificationErrorMessage = nil
        serviceErrorMessage = nil

        Task {
            do {
                _ = try await signupUseCase.requestPhoneVerificationCode(for: normalizedPhoneNumber)
                isVerificationRequested = true
            } catch {
                serviceErrorMessage = Self.message(for: error)
            }
            isSendingVerificationCode = false
        }
    }

    func updatePhoneNumber(_ value: String) {
        phoneNumber = Self.formattedPhoneNumber(value)
        phoneErrorMessage = nil
    }

    func updateProfileImage(data: Data?) {
        profileImageData = data
        profileImageErrorMessage = nil
    }

    func reportProfileImageLoadingFailure() {
        profileImageErrorMessage = "프로필 사진을 불러오지 못했어요. 사진 없이 계속할 수 있습니다."
    }

    private var trimmedIdentifier: String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedStudentNumber: String {
        studentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidPhoneNumber: Bool {
        let digits = phoneNumber.filter(\.isNumber)
        return (10...11).contains(digits.count)
    }

    private var normalizedPhoneNumber: String {
        phoneNumber.filter(\.isNumber)
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return "요청 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
    }

    private func validateIdentifier() -> Bool {
        identifierErrorMessage = trimmedIdentifier.isEmpty ? "아이디를 입력해주세요." : nil
        return identifierErrorMessage == nil
    }

    private func validatePassword() -> Bool {
        passwordErrorMessage = password.isEmpty ? "비밀번호를 입력해주세요." : nil
        confirmationErrorMessage = passwordConfirmation.isEmpty
            ? "비밀번호를 다시 입력해주세요."
            : (password == passwordConfirmation ? nil : "비밀번호가 일치하지 않습니다.")

        return passwordErrorMessage == nil && confirmationErrorMessage == nil
    }

    private func validatePhoneNumber() -> Bool {
        phoneErrorMessage = isValidPhoneNumber ? nil : "전화번호를 입력해주세요."
        return phoneErrorMessage == nil
    }

    private func validatePhoneVerification() -> Bool {
        guard validatePhoneNumber() else { return false }

        verificationErrorMessage = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "인증번호를 입력해주세요."
            : nil
        return verificationErrorMessage == nil
    }

    private func validateStudentInformation() -> Bool {
        studentNumberErrorMessage = trimmedStudentNumber.isEmpty ? "학번을 입력해주세요." : nil
        nameErrorMessage = trimmedName.isEmpty ? "이름을 입력해주세요." : nil

        return studentNumberErrorMessage == nil && nameErrorMessage == nil
    }

    private static func formattedPhoneNumber(_ value: String) -> String {
        let digits = String(value.filter(\.isNumber).prefix(11))

        return switch digits.count {
        case 0...3:
            digits
        case 4...7:
            "\(digits.prefix(3))-\(digits.dropFirst(3))"
        default:
            "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(4))-\(digits.dropFirst(7))"
        }
    }
}
