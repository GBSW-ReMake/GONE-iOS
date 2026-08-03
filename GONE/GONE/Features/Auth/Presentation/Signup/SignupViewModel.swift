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

        var title: String {
            switch self {
            case .identifier:
                "아이디를 입력해주세요"
            case .password:
                "비밀번호를 설정해주세요"
            case .phoneVerification:
                "전화번호를 입력해주세요"
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
            }
        }

        var actionTitle: String {
            self == .phoneVerification ? "가입 완료" : "다음"
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
    @Published var phoneNumber = "" {
        didSet {
            phoneNumber = Self.formattedPhoneNumber(phoneNumber)
            phoneErrorMessage = nil
        }
    }
    @Published var verificationCode = "" {
        didSet { verificationErrorMessage = nil }
    }

    @Published private(set) var identifierErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var confirmationErrorMessage: String?
    @Published private(set) var phoneErrorMessage: String?
    @Published private(set) var verificationErrorMessage: String?
    @Published private(set) var serviceErrorMessage: String?
    @Published private(set) var isVerificationRequested = false

    var isPrimaryActionEnabled: Bool {
        switch currentStep {
        case .identifier:
            !trimmedIdentifier.isEmpty
        case .password:
            !password.isEmpty && !passwordConfirmation.isEmpty
        case .phoneVerification:
            isValidPhoneNumber && !verificationCode.isEmpty
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

        isVerificationRequested = true
        verificationErrorMessage = nil
        serviceErrorMessage = "인증번호 발송 API 연결 정보를 확인 중입니다."
    }

    private var trimmedIdentifier: String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidPhoneNumber: Bool {
        let digits = phoneNumber.filter(\.isNumber)
        return (10...11).contains(digits.count)
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
