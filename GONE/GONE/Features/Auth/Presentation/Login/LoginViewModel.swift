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
    let role: AccountRole

    @Published private(set) var identifierErrorMessage: String?
    @Published private(set) var passwordErrorMessage: String?
    @Published private(set) var loginErrorMessage: String?
    @Published private(set) var isLoading = false

    private let loginUseCase: LoginUseCase?

    init(role: AccountRole = .student, loginUseCase: LoginUseCase? = nil) {
        self.role = role
        self.loginUseCase = loginUseCase
    }

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

    func login(with credentials: LoginCredentials) async throws {
        guard let loginUseCase else {
            showServiceUnavailableMessage()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await loginUseCase.execute(with: credentials)
        } catch let error as APIError {
            loginErrorMessage = error.localizedDescription
            throw error
        } catch {
            loginErrorMessage = "로그인 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
            throw error
        }
    }
}
