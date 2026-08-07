//
//  LoginViewModel.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var identifier = "" {
        didSet {
            if !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                identifierErrorMessage = nil
            }
        }
    }

    @Published var password = "" {
        didSet {
            if !password.isEmpty {
                passwordErrorMessage = nil
            }
        }
    }
    @Published var role: AccountRole = .student

    @Published private(set) var identifierErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var loginErrorMessage: String?

    var isLoginEnabled: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    func makeCredentials() -> LoginCredentials? {
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        identifierErrorMessage = trimmedIdentifier.isEmpty ? "아이디 또는 전화번호를 입력해주세요." : nil
        passwordErrorMessage = password.isEmpty ? "비밀번호를 입력해주세요." : nil
        loginErrorMessage = nil

        guard identifierErrorMessage == nil, passwordErrorMessage == nil else {
            return nil
        }

        return LoginCredentials(identifier: trimmedIdentifier, password: password, role: role)
    }

    func showServiceUnavailableMessage() {
        loginErrorMessage = "로그인 서비스 연결 정보를 확인 중입니다. 잠시 후 다시 시도해주세요."
    }
}
